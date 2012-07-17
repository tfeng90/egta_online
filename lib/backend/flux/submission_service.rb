class SubmissionService
  def initialize(login_connection)
    @login_connection = login_connection
  end
  
  def submit(simulation)
    begin
      channel = @login_connection.exec("qsub -V -r n #{Yetting.deploy_path}/simulations/#{simulation.number}/wrapper") do |ch, stream, data|
        if stream == :std_err
          simulation.fail "submission failed: #{data}"
        else
          job_return = data
          if job_return != nil
            job_return = job_return.split(".").first
            if job_return =~ /\A\d+\z/
              simulation.queue_as job_return.to_i
            else
              simulation.fail "submission failed: #{job_return}"
            end
          else
            simulation.fail "unknown submission failure"
          end
        end
      end
      channel.wait
    rescue Exception => e
      simulation.fail "failed in the submission step: #{e.message}"
    end
  end
end