class SampleRecordsToSymmetryGroups < Mongoid::Migration
  def self.up
    Simulator.where(_id: '4f60d65a4a98060bec000002').destroy_all
    profiles = Profile.where(:sample_count.gt => 0, :sample_records.ne => nil).limit(100)
    while profiles.count != 0
      puts profiles.count
      profiles.each do |profile|
        count = 0
        p "starting #{Time.now}"
        profile.features_observations.destroy_all
        profile.symmetry_groups.each do |symmetry_group|
          symmetry_group.players.destroy_all
        end
        profile["sample_records"].each do |sample_record|
          count += 1
          profile.features_observations.create(features: sample_record["features"], observation_id: count)
          profile.symmetry_groups.each do |symmetry_group|
            payoff = sample_record["payoffs"][symmetry_group.role][symmetry_group.strategy]
            symmetry_group.players << 1.upto(symmetry_group.count).collect{ |i| Player.new(payoff: payoff, observation_id: count) }
          end
        end
        profile.save
        flag = false
        profile.symmetry_groups.each do |symmetry_group|
          flag ||= (symmetry_group.payoff.round(5) != (profile["sample_records"].map{ |s| s["payoffs"][symmetry_group.role][symmetry_group.strategy] }.to_scale.mean).round(5))
          if flag
            puts "players #{symmetry_group.players.collect{|player| player.payoff}}"
            puts "sample_records #{profile["sample_records"].collect{ |s| s["payoffs"][symmetry_group.role][symmetry_group.strategy] }}"
          end
        end
        profile.unset("sample_records") unless flag
      end
      profiles = Profile.where(:sample_count.gt => 0, :sample_records.ne => nil).limit(100)
    end
  end

  def self.down
  end
end