require "open-uri"

class KeepaliveRestartBackendJob < Struct.new(:queue, :backend_id, :period)

  def perform
    backend = Backend.find backend_id
    if backend
      hostname = backend.hostname
      host_url = "http://#{hostname}"
      req = open(host_url) do |resp|
        if resp.status && resp.status[0].to_i >= 500
          frontend = backend.frontend
          job = DeployFrontendJobspec.new(frontend.deploy_frontend_job.id, frontend.host, "restart_remote_backend", backend.id, backend.name)
          DelayedJob.enqueue(job, :queue => "deploy-web")
        end
      end
      Delayed::Job.enqueue(self, :queue => queue, :run_at => Time.now + period.seconds)
    end
  end
end