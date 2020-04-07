# --
# Copyright (C) 2001-2018 OTRS AG, https://otrs.com/
# --
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
	
		my $Data;
		foreach my $ImportedCIValue (@ImportedCIValues)
		{
			my($Class, $Definition) = split(/::/, $ImportedCIValue, 2);
			next if $Class ne $LastVersion->{Class};
			
			if ($Definition =~ m/::/) 
			{
				my @spl = split('::', $Definition);
				my $DataName;
				my $DataValue;
				if (scalar @spl eq '2')
				{
					$DataName = $spl[0];
					$DataValue = $LastVersion->{XMLData}->[1]->{Version}->[1]->{$spl[0]}->[$spl[1]]->{Content} || 0;
				}
				elsif (scalar @spl eq '4')
				{
					$DataName = " ** $spl[2]";
					$DataValue = $LastVersion->{XMLData}->[1]->{Version}->[1]->{$spl[0]}->[$spl[1]]->{$spl[2]}->[$spl[3]]->{Content} || 0;
				}
				
				elsif (scalar @spl eq '6')
				{
					$DataName = " **** $spl[4]";
					$DataValue = $LastVersion->{XMLData}->[1]->{Version}->[1]->{$spl[0]}->[$spl[1]]->{$spl[2]}->[$spl[3]]->{$spl[4]}->[$spl[5]]->{Content} || 0;
				}
				
				$Data .= "$DataName : ";
				$Data .= $DataValue;
				$Data .= "\n";
			}
			else
			{
				$Data .= "$Definition : $LastVersion->{$Definition}\n";
			}
			
		}
		
		#TODO: To support further level of ci definition.
	
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
					ValueText => $Data,
				},
				
			],
			UserID   => 1,
		);
	
	
	} 
	
		
}

1;
