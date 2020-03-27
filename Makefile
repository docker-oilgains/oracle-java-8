phusion: .PHONY
		 make -C oses/ _phusion
ubuntu14: .PHONY
		  make -C oses/ _ubuntu14		 
ubuntu16: .PHONY
		  make -C oses/ _ubuntu16
ubuntu18: .PHONY
		  make -C oses/ _ubuntu18
debian9: .PHONY
		  make -C oses/ _debian9
debian10: .PHONY
		  make -C oses/ _debian10


.PHONY:
	echo "Building Oracle Java 8 for few Linux OSes locally...\n"


all:
		phusion ubuntu14 ubuntu16 ubuntu18 debian9
