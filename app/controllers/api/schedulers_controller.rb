class Api::SchedulersController < Api::BaseController
  def index
    respond_with(ApiScheduler.all)
  end
  
  def add_profile
    puts params
    scheduler = ApiScheduler.find(params[:id])
    puts scheduler.inspect
    proto_string = Profile.convert_to_proto_string(params[:profile_name])
    if proto_string != ""
      profile = Profile.find_or_create_by(simulator_id: scheduler.simulator_id,
                                            parameter_hash: scheduler.parameter_hash,
                                            size: Profile.size_of_profile(proto_string),
                                            proto_string: proto_string)
      if profile.valid?
        scheduler.profile_ids << profile.id
        scheduler.save!
        respond_with(profile, :location => profile_path(profile))
      else
        respond_with(profile)
      end
    else
      respond_with({:error => "invalid profile name"})
    end
  end
end