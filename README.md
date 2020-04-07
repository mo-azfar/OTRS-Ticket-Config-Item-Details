# OTRS-Ticket-Config-Item-Details  
- Built for OTRS CE v 6.0.x  
- Get Config Item additional details from dynamic field ITSMConfigItemReference and and update it to another specific ticket dynamic field.   
- This is an extension features of DynamicFieldITSMConfigItem addon from OPARL.  

https://opar.perl-services.de/dist/DynamicFieldITSMConfigItem-6.0.1  


1. Two ticket dynamic field must be create and configure.

Example:

a)	Name: Anything #example: ContractCI  
	  Field Type: ITSMConfigItemReference #must use this type  
	  MaxArraySize: 1 #must be 1
	
	
b)	Name:  Anything  #example: ContractCIDetails  
	  Field Type: Textarea  



2. Defines the CI values that need to be pull into dynamic field at System Configuration > TicketCIDetails::CIValuesByClass.  
- Each entry must be prefixed with the class name and double colons.  
- Supported up to 3 level definition.  

Example:

1st level -> Software::Name  
1st level -> Software::LicenceKey::1  
2nd level -> Software::LicenceKey::1::Quantity::1  
3rd level -> Software::LicenceKey::1::Quantity::1::Major::1



3. Admin must create a new Generic Agent (GA) with option to execute custom module.

Execute Custom Module => Module => Kernel::System::Ticket::Event::TicketCIDetails
	
[MANDATORY PARAM]
Param 1 Key => SourceDF  
Param 1 Value => ContractCI #Name of the source dynamic field ITSMConfigItemReference 

Param 2 Key => DestinationDF  
Param 2 Value => ContractCIDetails  #Name of the target dynamic field    	



[![Capture.png](https://i.postimg.cc/k4XQXg9c/Capture.png)](https://postimg.cc/cK2gFZvg)


[![Capture2.png](https://i.postimg.cc/zvLbQLSy/Capture2.png)](https://postimg.cc/JHLzDzF8)
