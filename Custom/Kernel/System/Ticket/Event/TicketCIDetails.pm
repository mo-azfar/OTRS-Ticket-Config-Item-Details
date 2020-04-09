# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --
#
##REF http://doc.otrs.com/doc/api/otrs/6.0/Perl/index.html
package Kernel::System::Ticket::Event::TicketCIDetails;

use strict;
use warnings;
use Data::Dumper;

our @ObjectDependencies = (
    'Kernel::System::Ticket',
	'Kernel::System::ITSMConfigItem',
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # 0=off; 1=on;
    $Self->{Debug} = $Param{Debug} || 1;

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;
	
	# check needed param
    if ( !$Param{TicketID} || !$Param{New}->{'SourceDF'} || !$Param{New}->{'DestinationDF'} ) {
        $Kernel::OM->Get('Kernel::System::Log')->Log(
            Priority => 'error',
            Message  => 'Need TicketID || SourceDF || DestinationDF Param and Value for this operation',
        );
        return;
    }
	
	my $TicketID = $Param{TicketID};  ##This one if using GenericAgent ticket event
	my $Source = $Param{New}->{'SourceDF'}; ##This one if using GenericAgent ticket event
	my $Destination = $Param{New}->{'DestinationDF'}; ##This one if using GenericAgent ticket event
	
	#get ticket object
	my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
	#get general catalog object
	my $GeneralCatalogObject = $Kernel::OM->Get('Kernel::System::GeneralCatalog');
	#get config item asset object
	my $ConfigItemObject = $Kernel::OM->Get('Kernel::System::ITSMConfigItem');
	my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
	# get ticket content
	my %Ticket = $TicketObject->TicketGet(
        TicketID => $TicketID ,
		UserID        => 1,
		DynamicFields => 1,
		Extended => 0,
    );
	
	return if !%Ticket;
	#print "Content-type: text/plain\n\n";
	#print Dumper(\%Ticket);
	
	#Get config data on mapping xml	
    my @ImportedCIValues = @{ $ConfigObject->Get('TicketCIDetails::CIValuesByClass') };

	#since this CI DF result return array,
	foreach my $ConfigItemID (@{$Ticket{'DynamicField_'.$Param{New}->{'SourceDF'}}})  
	{ 
		my $LastVersion = $ConfigItemObject->VersionGet(
				ConfigItemID => $ConfigItemID,
				XMLDataGet   => 1,
		);
				
		my $XMLData = $LastVersion->{XMLData}->[1]->{Version}->[1];
		my $Data1;
		#search in xml definition to get the CI Name based on CI Key (passed from configuration)
		#up to 3rd level definition
		foreach my $ImportedCIValue (@ImportedCIValues)
		{ 
		  my($Class, $Definition) = split(/::/, $ImportedCIValue, 2);
		  next if $Class ne $LastVersion->{Class};
		  
		  if ($Definition =~ m/::/) 
		  { 
		    my @array = split('::', $Definition); #split definition by :: into array for searching in xml data
		    my @new_array = grep {$_ ne '1' && $_ ne '2' && $_ ne '3'} @array; #remove number from array for searching in xml definition
		    
		    if (scalar @new_array eq '1') #defintion 1st level
		    { 
		      no warnings qw(uninitialized);
		      my ($hash_ref) = grep {$_->{Key} eq "$new_array[0]" } @{$LastVersion->{XMLDefinition}};
		              
		      #get xml value
		      #print $XMLData->{$hash_ref->{Key}}->[$array[1]]->{Content};
		      #print $XMLData->{InstallDate}->[1]->{Content};
		      $Data1 .= "[$hash_ref->{Name}]: $XMLData->{$hash_ref->{Key}}->[$array[1]]->{Content}\n";
		          
		    }
		    elsif (scalar @new_array eq '2') #defintion 2nd level
		    {
		      no warnings qw(uninitialized);
		      my ($hash_ref) = grep { $_->{Sub}->[0]->{Key} eq "$new_array[1]" } @{$LastVersion->{XMLDefinition}};
		      
		      #get xml value
		      #print $XMLData->{$hash_ref->{Key}}->[$array[1]]->{$array[2]}->[$array[3]]->{Content};
		      #print  $XMLData->{InstallDate}->[1]->{By}->[1]->{Content};
		      $Data1 .= "*$hash_ref->{Sub}->[0]->{Name}: $XMLData->{$hash_ref->{Key}}->[$array[1]]->{$array[2]}->[$array[3]]->{Content}\n";
		        
		    }
		    elsif (scalar @new_array eq '3') #defintion 3rd level
		    {
		      no warnings qw(uninitialized);
		      my ($hash_ref) = grep { $_->{Sub}->[0]->{Sub}->[0]->{Key} eq "$new_array[2]" } @{$LastVersion->{XMLDefinition}};
		      
		      #get xml value
		      #print $XMLData->{$hash_ref->{Key}}->[$array[1]]->{$array[2]}->[$array[3]]->{$array[4]}->[$array[5]]->{Content};
		      #print $XMLData->{InstallDate}->[1]->{By}->[1]->{Backup}->[1]->{Content};
		      $Data1 .= "**$hash_ref->{Sub}->[0]->{Sub}->[0]->{Name}: $XMLData->{$hash_ref->{Key}}->[$array[1]]->{$array[2]}->[$array[3]]->{$array[4]}->[$array[5]]->{Content}\n";
		      
		    }
		  } 
		  else
		  {
		    $Data1 .= "[$Definition] : $LastVersion->{$Definition}\n";
		  }
		
		}
	
		##REF  http://doc.otrs.com/doc/api/otrs/6.0/Perl/Kernel/System/DynamicFieldValue.pm.html#ValueSet (OTRS 6)
		my $DynamicFieldValueObject = $Kernel::OM->Get('Kernel::System::DynamicFieldValue');
		#get dynamic field object
		my $DynamicFieldObject = $Kernel::OM->Get('Kernel::System::DynamicField'); 
		
		my $DF01Get = $DynamicFieldObject->DynamicFieldGet(
			Name => $Param{New}->{'DestinationDF'},
			);
		
		##update df
		my $DF01Set = $DynamicFieldValueObject->ValueSet(
			FieldID  => $DF01Get->{ID},                
			ObjectID => $TicketID,              								
			Value    => [
				{
					ValueText => $Data1,
				},
				
			],
			UserID   => 1,
		);
	
	
	} 
		
}

1;
