require 'fileutils'

class Noprocast
	class << self
		def default_hosts
			['news.ycombinator.com', 'twitter.com', 'facebook.com', 'reddit.com']
		end

		def deny_file_path
			File.expand_path("~/.noprocast")
		end

		def current_hosts
			setup_deny_file_if_required!
			File.read(deny_file_path).split(/\n/).select { |line| line.match(/[a-zA-Z0-9]/) }.map(&:strip)
		end

		def hosts_file_content
			File.read("/etc/hosts")
		end

		def activate!
			backup_hosts_file_if_required!
			deactivate!   # ensure that /etc/hosts is clean
			File.open("/etc/hosts", 'a') do |file|
				file << "\n\n# noprocast start\n#{current_hosts.map { |host| "127.0.0.1 #{host}" }.join("\n")}\n# noprocast end"
			end
		end

		def deactivate!
			clean_hosts = hosts_file_content.gsub(/(\n\n)?\# noprocast start.*\# noprocast end/m, '')
			File.open("/etc/hosts", 'w') do |file|
				file << clean_hosts
			end	
		end

		def active?
			hosts_file_content.match(/\# noprocast start/)
		end

		def status_message
			active? ? "noprocast enabled for #{current_hosts.size} hosts" : "noprocast disabled"
		end

		def backup_hosts_file_if_required!
			unless File.exists?("/etc/.hosts.noprocastbackup")
				FileUtils.cp("/etc/hosts", "/etc/.hosts.noprocastbackup")
			end
		end

		def setup_deny_file_if_required!
			unless File.exists?(deny_file_path)
				File.open(deny_file_path, 'w') do |file|
					file << default_hosts.join("\n")
				end
			end
		end

		def edit!
			editor = ENV['EDITOR'] || 'vi'
			system "#{editor} #{deny_file_path}"
		end
	end
end

