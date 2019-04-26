# encoding: utf-8
title 'Terraform validation'

control 'terraform' do
	impact 1
	title 'Run packer validate'

	modules = command('cd terraform/ && find modules/ -mindepth 1 -maxdepth 1 -type d').stdout.split("\n")
	environments = ['stage/', 'prod/']
  	all_folders = modules + environments
  	all_folders.each do |fname|
	    unless modules.include?(fname)  # We don't expect to see terraform.tfvars.example in folders with modules, thus skip validation
	    	describe command("cd terraform/#{fname} && terraform init -backend=false && terraform validate -var-file=terraform.tfvars.example") do
	    		its('stdout') { should match "Terraform has been successfully initialized!" }
	      		its('stderr') { should eq "" }
	      		its('exit_status') { should eq 0 }
	    	end
	    end
	    describe command("cd terraform/#{fname} && tflint --var-file=terraform.tfvars.example --deep -q") do
	      its('stdout') { should eq "" }
	      its('stderr') { should eq "" }
	      its('exit_status') { should eq 0 }
	    end
  	end
end
