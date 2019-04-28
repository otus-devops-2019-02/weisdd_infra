# encoding: utf-8
title 'Packer templates validation'

control 'packer' do
	impact 1
	title 'Run packer validate'

	files = command('find packer -maxdepth 1 ! -name "variables*.json" -name "*.json" -type f').stdout.split("\n")
  	files.each do |fname|
	    describe command("packer validate -var-file=packer/variables.json.example #{fname}") do
	      its('stdout') { should eq "Template validated successfully.\n" }
	      its('exit_status') { should eq 0 }
	    end
  	end
end
