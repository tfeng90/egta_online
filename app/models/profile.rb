class Profile
  include Mongoid::Document
  
  embeds_many :symmetry_groups, as: :role_strategy_partitionable
  embeds_many :observations

  has_many :simulations, :dependent => :destroy
  belongs_to :simulator

  field :size, type: Integer
  field :assignment, type: String
  field :sample_count, type: Integer, default: 0
  field :features, type: Hash
  field :configuration, type: Hash, default: {}
  
  attr_accessible :assignment, :configuration

  index ({ simulator_id: 1, configuration: 1, size: 1 })
  index ({ _id: 1, sample_count: 1, assignment: 1 })

  validates_presence_of :simulator
  validates_format_of :assignment, with: /\A(\w+:( \d+ [\w:.-]+,)* \d+ [\w:.-]+; )*\w+:( \d+ [\w:.-]+,)* \d+ [\w:.-]+\z/
  validates_uniqueness_of :assignment, scope: [:simulator_id, :configuration]
  delegate :fullname, :to => :simulator, :prefix => true

  has_and_belongs_to_many :games, index: true, inverse_of: nil
  
  has_and_belongs_to_many :schedulers, index: true, inverse_of: nil do
    def with_max_samples
      @target.max{ |x, y| x.required_samples(id) <=> y.required_samples(id) }
    end
  end
  
  scope :with_game, ->(game){ where(game_ids: game.id) }
  scope :with_scheduler, ->(scheduler){ where(scheduler_ids: scheduler.id) }
  scope :with_role_and_strategy, ->(role, strategy){ elem_match(symmetry_groups: { role: role, strategy: strategy }) }
  
  after_create :find_games
  
  def strategies_for(role_name)
    symmetry_groups.where(role: role_name).collect{ |s| s.strategy }.uniq
  end
  
  def find_games
    Resque.enqueue(GameAssociater, id)
  end

  def try_scheduling
    Resque.enqueue_in(5.minutes, ProfileScheduler, id)
  end

  def create_player(role, strategy, payoff, pfeatures)
    symmetry_groups.where(role: role, strategy: strategy).first.players.create(payoff: payoff.to_f, features: pfeatures)
  end
  
  def scheduled?
    simulations.active.count > 0
  end
  
  def features
    fhash = Hash.new{ |hash,key| hash[key] = [] }
    features_observations.each do |f|
      f.features.each do |key, value|
        fhash[key] << value
      end
    end
    fhash.each do |key, value|
      fhash[key] = value.compact
      fhash[key] = fhash[key].reduce(:+)/fhash[key].size
    end
    fhash
  end
  
  def as_json(options={})
    if options[:granularity] == 'summary'
      {
        id: self.id,
        sample_count: self.sample_count,
        #symmetry_groups: self.symmetry_groups.collect{ |symmetry_group| { role: symmetry_group.role, strategy: symmetry_group.strategy, count: symmetry_group.count, payoff: symmetry_group.payoff, payoff_sd: symmetry_group.payoff_sd } }
      }
    end
  end
end