# encoding: utf-8
title 'Ansible playbooks validation'

control 'ansible' do
	impact 1
	title 'Run ansible-lint'

	files = command('find ansible/playbooks ! -name "inventory*.yml" -name "*.yml" -type f').stdout.split("\n")
  	files.each do |fname|
	    describe command("ansible-lint #{fname} --exclude=ansible/roles/jdauphant.nginx") do
	      its('stdout') { should eq '' }
	      its('stderr') { should eq '' }
	      its('exit_status') { should eq 0 }
	    end
  	end
end
