use strict;
use warnings FATAL => 'all';

package MarpaX::RFC::RFC3629;

# ABSTRACT: Marpa parsing of UTF-8 byte sequences as per RFC3629

# VERSION

# AUTHORITY

use Carp qw/croak/;
use Encode qw/decode/;
use Marpa::R2;
use Moo;
use Types::Standard -all;
use Types::Encodings qw/Bytes/;

has input     => ( is => 'ro',  isa => Bytes, required => 1, trigger => 1);
has encoding  => ( is => 'ro',  isa => Str, default => sub { 'UTF-8' } );
has output    => ( is => 'rwp', isa => Str|Undef);

our $DATA = do { local $/; <DATA> };
our $G = Marpa::R2::Scanless::G->new({source => \$DATA});

sub BUILDARGS {
  my ($class, @args) = @_;

  unshift @args, 'input' if @args % 2 == 1;
  return { @args };
}

sub _trigger_input { my $self = shift;
                     my $value = ${$G->parse(\shift, {
                                                      # trace_terminals => 1,
                                                      # trace_values => 1
                                                     })};
                     $self->_set_output(decode($self->encoding, $value, Encode::FB_CROAK))
                   }
sub _concat        { shift; join('', @_) }

1;

__DATA__
:default ::= action => MarpaX::RFC::RFC3629::_concat
:start        ::= <UTF8 octets>
<UTF8 octets> ::= <UTF8 char>*
<UTF8 char>   ::= <UTF8 1>
                | <UTF8 2>
                | <UTF8 3>
                | <UTF8 4>
<UTF8 1>      ::=                                                 [\x{00}-\x{7F}]
<UTF8 2>      ::=                                 [\x{C2}-\x{DF}]     <UTF8 tail>
<UTF8 3>      ::=                        [\x{E0}] [\x{A0}-\x{BF}]     <UTF8 tail>
                |                 [\x{E1}-\x{EC}]     <UTF8 tail>     <UTF8 tail>
                |                        [\x{ED}] [\x{80}-\x{9F}]     <UTF8 tail>
                |                 [\x{EE}-\x{EF}]     <UTF8 tail>     <UTF8 tail>
<UTF8 4>      ::=        [\x{F0}] [\x{90}-\x{BF}]     <UTF8 tail>     <UTF8 tail>
                | [\x{F1}-\x{F3}]     <UTF8 tail>     <UTF8 tail>     <UTF8 tail>
                |        [\x{F4}] [\x{80}-\x{8F}]     <UTF8 tail>     <UTF8 tail>
<UTF8 tail>   ::= [\x{80}-\x{BF}]
