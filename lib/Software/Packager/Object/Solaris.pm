################################################################################
# Name:		Software::Packager::Object::Solaris.pm
# Description:	This module is used by Packager for holding data for a each item
# Author:	Bernard Davison
# Contact:	rbdavison@cpan.org
#

package		Software::Packager::Object::Solaris;

####################
# Standard Modules
use strict;
#use File::Basename;
# Custom modules
use Software::Packager::Object;

####################
# Variables
our @ISA = qw( Software::Packager::Object );
our @EXPORT = qw();
our @EXPORT_OK = qw();
our $VERSION = 0.01;

####################
# Functions

################################################################################
# Function:	_check_data()
# Description:	This function checks the passed data
#	TYPE 		- If the type is a file then the value of SOURCE must
#			  be a real file.
#			  If the type is a soft/hard link then the source and
#			  destination must both be present.
#	SOURCE		- nothing special to check
#	DESTINATION	- nothing special to check
#	CLASS		- if it is not set then set to "none"
#	PART		- if it is not set then set to "1"
#	MODE		- Defaults to 0777 for directories and for files the
#			  permissions currently set.
#	USER		- Defaults to the current user
#	GROUP		- Defaults to the current users primary group
# Arguments:	$self
# Return:	true if all OK else undef.
#
sub _check_data
{
	my $self = shift;

	$self->{'TYPE'} = lc $self->{'TYPE'};
	if ($self->{'TYPE'} eq 'file')
	{
	    return undef unless -f $self->{'SOURCE'};
	}
	elsif ($self->{'TYPE'} =~ /link/)
	{
	    return undef unless $self->{'SOURCE'} and $self->{'DESTINATION'};
	}

	unless ($self->{'MODE'})
	{
	    if ($self->{'TYPE'} eq 'directory')
	    {
		$self->{'MODE'} = 0755;
	    }
	    else
	    {
		$self->{'MODE'} =  sprintf("%04o", (stat($self->{'SOURCE'}))[2] & 07777);
	    }
	}

	# make sure PART is set to a number
	if (scalar $self->{'PART'})
	{
		#return undef unless $self->{'PART'} =~ /\d+/;
		$self->{'PART'} =~ /\d+/;
	}
	else
	{
		$self->{'PART'} = 1;
	}

	$self->{'CLASS'} = "none" unless scalar $self->{'CLASS'};
	$self->{'USER'} = getpwuid($<) unless $self->{'USER'};

	unless ($self->{'GROUP'})
	{
	    my $groups = $(;
	    my ($group, $crap) = split / /, $groups;
	    $self->{'GROUP'} = getgrgid($group);
	}

	return 1;
}

################################################################################
# Function:	status()
# Description:	This function returns the status for this object.
# Arguments:	none.
# Return:	package directory.
#
sub status
{
	my $self = shift;
	return $self->get_value('STATUS');
}

################################################################################
# Function:	class()
# Description:	This function returns the class for this object.
# Arguments:	none.
# Return:	object class
#
sub class
{
	my $self = shift;
	return $self->get_value('CLASS');
}

################################################################################
# Function:	part()
# Description:	This function returns the part for this object.
# Arguments:	none.
# Return:	object part
#
sub part
{
	my $self = shift;
	return $self->get_value('PART');
}

################################################################################
# Function:	prototype()
# Description:	This function returns the object type for the object as
#		described in prototype(4) man page.
# Arguments:	$self
# Return:	object type
#
sub prototype
{
	my $self = shift;
	my %proto_types = (
		'block'		=> 'b',
		'charater'	=> 'c',
		'directory'	=> 'd',
		'edit'		=> 'e',
		'file'		=> 'f',
		'installation'	=> 'i',
		'hardlink'	=> 'l',
		'pipe'		=> 'p',
		'softlink'	=> 's',
		'volatile'	=> 'v',
		'exclusive'	=> 'x',
	);

	return $proto_types{$self->{'TYPE'}};
}

1;
__END__
