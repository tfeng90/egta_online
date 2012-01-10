class ProfileScheduler
  @queue = :profile_actions

  def self.perform(profile_id)
    profile = Profile.find(profile_id) rescue nil
    if profile != nil
      if profile.simulations.scheduled.count == 0
        sample_count = profile.simulations.active.scheduled.reduce(0) {|sum, sch| sum+sch.size} + profile.sample_count
        max_schedulable = Scheduler.where(profile_ids: profile.id).active.collect {|s| s.max_samples}.push(0).max
        if max_schedulable > sample_count
          scheduler = Scheduler.active.where(profile_ids: profile.id, max_samples: max_schedulable).sample
          num_samples = [scheduler.samples_per_simulation, max_schedulable-sample_count].min
          simulation = profile.simulations.create!(size: num_samples, state: 'pending', account_id: Account.active.sample.id)
          scheduler.simulations << simulation
          simulation.save!
        end
      end
    end
  end
end