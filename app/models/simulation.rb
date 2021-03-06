class Simulation
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Sequence

  belongs_to :profile, inverse_of: :simulations
  belongs_to :scheduler, inverse_of: :simulations
  delegate :nodes, to: :scheduler, prefix: true
  delegate :simulator_fullname, to: :scheduler

  field :size, type: Integer
  field :state
  field :job_id
  field :error_message, default: ''
  field :profile_assignment
  field :_id, type: Integer
  field :flux, type: Boolean, default: false
  sequence :_id
  index({ state: 1 })

  def self.simulation_limit
    [[Backend.configuration.queue_quantity, Backend.configuration.queue_max-Simulation.active.count].min, 0].max
  end

  scope :pending, where(state: 'pending')
  scope :queued, where(state: 'queued')
  scope :running, where(state: 'running')
  scope :processing, where(state: 'processing')
  scope :stale, where(:state.in=>['queued', 'complete', 'failed']).and(:updated_at.lt => (Time.current-300000))
  scope :active, where(:state.in=>['queued','running'])
  scope :recently_finished, where(:state.in=>['complete', 'failed'], :updated_at.gt => (Time.current-86400))
  scope :scheduled, where(:state.in=>['pending','queued','running'])
  scope :queueable, pending.order_by([[:created_at, :asc]]).limit(simulation_limit)
  validates_inclusion_of :state, in: ['pending', 'queued', 'running', 'failed', 'processing', 'complete']
  validates_presence_of :profile_id
  validates_numericality_of :size, only_integer: true, greater_than: 0

  before_save(on: :create){ self.profile_assignment = Profile.where(_id: self.profile_id).without(:observations).first.assignment }
  before_destroy :cleanup

  def cleanup
    LocalSimulationCleanup.perform_async(id)
    # BackendSimulationCleanup.perform_async(id)
  end

  def start
    self.update_attributes(state: 'running') if self.state == 'queued'
  end

  def finish
    self.update_attributes(state: 'complete')
    requeue
  end

  def process
    self.update_attributes(state: 'processing')
    DataParser.perform_async(id)
  end

  def queue_as(jid)
    self.update_attributes(job_id: jid, state: 'queued')
  end

  def fail(message)
    self.update_attributes(error_message: message, state: 'failed')
    requeue
  end

  def requeue
    ProfileScheduler.perform_in(5.minutes, profile_id)
  end
end