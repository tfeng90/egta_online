# Each Profile instance represents a single possible Strategy set for a Game.

class Profile
  include Mongoid::Document
  include Mongoid::Timestamps::Updated
  embeds_many :role_instances
  has_many :simulations, dependent: :destroy
  embeds_many :sample_records
  belongs_to :simulator, index: true
  field :proto_string
  field :size, type: Integer
  index ([[:parameter_hash, Mongo::DESCENDING], [:proto_string, Mongo::DESCENDING]]), unique: true
  field :parameter_hash, type: Hash, default: {}
  field :feature_avgs, type: Hash, default: {}
  field :feature_stds, type: Hash, default: {}
  field :feature_expected_values, type: Hash, default: {}
  after_create :find_games
  validates_presence_of :simulator, :proto_string, :parameter_hash
  validates_uniqueness_of :proto_string, scope: [:simulator_id, :parameter_hash]

  def to_yaml
    ret_hash = {}
    proto_string.split("; ").each do |atom|
      ret_hash[atom.split(": ")[0]] = atom.split(": ")[1].delete("[]").split(", ")
    end
    ret_hash
  end

  def name
    proto_string
  end
  
  def sample_count
    sample_records.count
  end
  
  def contains_strategy?(role, strategy)
    retval = false
    proto_string.split("; ").each do |atom|
      retval = true if atom.split(": ")[0] == role && atom.split(": ")[1].delete("[]").split(", ").include?(strategy)
    end
    return retval
  end

  def find_games
    Resque.enqueue(GameAssociater, id)
  end
  
  def try_scheduling
    Resque.enqueue(ProfileScheduler, id)
  end
end
