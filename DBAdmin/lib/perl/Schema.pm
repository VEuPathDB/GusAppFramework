#!/usr/bin/perl

# -----------------------------------------------------------------------
# Schema.pm
#
# An Oracle schema (object owner).
#
# Created: Sun Feb 25 14:55:55 EST 2001
#
# Jonathan Crabtree
#
# $Revision$ $Date$ $Author$
# -----------------------------------------------------------------------

package Schema;

use Util;

# -----------------------------------------------------------------------
# Constructor
# -----------------------------------------------------------------------

sub new {
    my($class, $args) = @_;

    my $self = {
        name => $args->{name},
    };

    bless $self, $class;
    return $self;
}

# -----------------------------------------------------------------------
# Schema
# -----------------------------------------------------------------------

sub toString {
    my($self) = @_;
    return $self->{name};
gettables}

# Return an arrayref of all the tables owned by this schema.
#
sub getTables {
    my($self, $dbh) = @_;
    my $nm = $self->{name};
    my $sql = ("select table_name from all_tables where owner = upper('$nm')");
    return &Util::execQuery($dbh, $sql, 'scalar');
}

# Return an arrayref of all the views owned by this schema.
#
sub getViews {
    my($self, $dbh) = @_;
    my $nm = $self->{name};
    my $sql = ("select view_name from all_views where owner = upper('$nm')");
    return &Util::execQuery($dbh, $sql, 'scalar');
}

# Return an arrayref of all the sequences owned by this schema.
#
sub getSequences {
    my($self, $dbh) = @_;
    my $nm = $self->{name};
    my $sql = ("select sequence_name from all_sequences where sequence_owner = upper('$nm')");
    return &Util::execQuery($dbh, $sql, 'scalar');
}

1;
