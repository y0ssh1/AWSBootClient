require 'aws-sdk'

class SetupSSH
  class << self
    @@client = Aws::EC2::Client.new(access_key_id: ENV['GPU_AWS_ACCESS_ID'], secret_access_key: ENV['GPU_AWS_ACCESS_SECRET'])

    def fetch
      ids = fetch_instances(state: 'stopped').map(&:instance_id)
      @@client.start_instances(instance_ids: ids)
      @@client.wait_until(:instance_running, instance_ids: ids)
      config = fetch_instances(state: 'running').map(&:public_ip_address)
        .map { |ip_address| config_for_instance(ip_address) }
        .flatten
        .join("\n")

      target_dir = "#{ENV['HOME']}/.ssh/conf.d"
      FileUtils.mkdir_p(target_dir)
      File.write("#{target_dir}/config_essay", config)
      p config
    end

    def stop
      ids = fetch_instances(state: 'running').map(&:instance_id)
      @@client.stop_instances(instance_ids: ids)
      begin
        @@client.wait_until(:instance_stopped, instance_ids: ids) do |w|
          w.interval = 15
          w.max_attempts = 20
        end
        p 'instances have stopped'
      rescue Aws::Waiters::Errors::WaiterFailed => error
        p "failed waiting for stopping instance: #{error.message}"
      end
    end

    private

    def fetch_instances(state:)
      @@client
        .describe_instances
        .reservations
        .map { |r| r.instances.select { |i| i.state.name == state } }
        .flatten
    end

    def config_for_instance(ip_address)
      <<~EOS
        Host gpu-#{ip_address}
        HostName #{ip_address}
        User ubuntu
        LocalForward 8888 localhost:8888
        IdentityFile ~/.ssh/make/gpu.pem
      EOS
    end
  end
end
