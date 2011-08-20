# This class performs the asynchronous assignment of a SymmetricProfile to a Scheduler
# If a matching SymmetricProfile does not already exist, a new one is created
# Scheduler is untyped for a flexibility, since more than one type of scheduler may want to schedule SymmetricProfiles, e.g. a SymmetricDeviationScheduler

class SymmetricProfileAssociater
  # All asynchronous jobs must specify a queue to be pushed on
  # All actions that involve profile creation and assignment should use this queue to ensure consistency
  @queue = :profile_actions

  # All asynchronous jobs must implement self.perform
  # Asynchronous jobs can only take simple objects, such as strings or numbers, as arguments
  # scheduler_id is the id that MongoDB uses to find the scheduler
  # proto_string is a string that identifies a profile; e.g. a 2 player SymmetricProfile where one player plays A and the other plays B has the proto_string 'A, B'
  # For SymmetricProfiles, proto_string is always assumed to have strategies in alphabetical order
  def self.perform(scheduler_id, proto_string)
    
    # Make sure that the scheduler still exists
    scheduler = Scheduler.find(scheduler_id) rescue nil
    if scheduler != nil
      profile = SymmetricProfile.find_or_create_by(simulator_id: scheduler.simulator_id,
                                                parameter_hash: scheduler.parameter_hash,
                                                proto_string: proto_string)    
      
      # This is the standard pattern in Mongoid for adding referenced documents to the referencer
      # First the Ruby object is added to the reference array of the parent
      # Then the Ruby object is persisted to a database document, at which point the document of the parent is also updated to reference the child
      scheduler.profiles << profile
      profile.save!
    end
  end
end