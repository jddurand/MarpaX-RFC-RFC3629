use strict;
use warnings FATAL => 'all';

package MarpaX::RFC::RFC3629;

# ABSTRACT: Marpa parsing of UTF-8 byte sequences as per RFC3629

# VERSION

# AUTHORITY

=head1 DESCRIPTION

This module is parsing byte sequences as per RFC3629. It will croak if parsing fails.

=head1 SYNOPSIS

    use strict;
    use warnings FATAL => 'all';
    use MarpaX::RFC::RFC3629;
    use Encode qw/encode/;
    use Data::HexDump;
    #
    # Parse octets
    #
    my $orig = "\x{0041}\x{2262}\x{0391}\x{002E}";
    my $octets = encode('UTF-8', $orig, Encode::FB_CROAK);
    my $string = MarpaX::RFC::RFC3629->new($octets)->output;
    print STDERR "Octets:\n" . HexDump($octets) . "\n";
    print STDERR "String:\n" . HexDump($string) . "\n";

=head1 SUBROUTINES/METHODS

=head2 new(ClassName $class: Bytes $octets --> InstanceOf['MarpaX::RFC::RFC3629'])

Instantiate a new object. Takes as parameter the octets.

=head2 output(InstanceOf['MarpaX::RFC::RFC3629'] $self --> Str)

Returns the UTF-8 string (utf8 flag might be on, depends).

=cut

use Encode qw/decode/;
use Marpa::R2;
use Moo;
use Types::Standard -all;
use Types::Encodings qw/Bytes/;

has input     => ( is => 'ro',  isa => Bytes, required => 1, trigger => 1);
has output    => ( is => 'rwp', isa => Str|Undef);

our $DATA = do { local $/; <DATA> };
our $G = Marpa::R2::Scanless::G->new({source => \$DATA});

sub BUILDARGS {
  my ($class, @args) = @_;

  unshift @args, 'input' if @args % 2 == 1;
  return { @args };
}

sub _trigger_input { shift->_set_output(decode('UTF-8', ${$G->parse(\shift)}, Encode::FB_CROAK)) }
sub _concat        { shift; join('', @_) }

=head1 SEE ALSO

L<Syntax of UTF-8 Byte Sequences|https://tools.ietf.org/html/rfc3629#section-4>

L<Marpa::R2>

=cut

1;

__DATA__
lexeme default = latm => 1
:default ::= action => MarpaX::RFC::RFC3629::_concat
:start        ::= <UTF8 octets>
<UTF8 octets> ::= <UTF8 char>*
<UTF8 char>   ::= <UTF8 1>
                | <UTF8 2>
                | <UTF8 3>
                | <UTF8 4>
<UTF8 1>        ~                                                 [\x{00}-\x{7F}]
<UTF8 2>        ~                                 [\x{C2}-\x{DF}]     <UTF8 tail>
<UTF8 3>        ~                        [\x{E0}] [\x{A0}-\x{BF}]     <UTF8 tail>
                |                 [\x{E1}-\x{EC}]     <UTF8 tail>     <UTF8 tail>
                |                        [\x{ED}] [\x{80}-\x{9F}]     <UTF8 tail>
                |                 [\x{EE}-\x{EF}]     <UTF8 tail>     <UTF8 tail>
<UTF8 4>        ~        [\x{F0}] [\x{90}-\x{BF}]     <UTF8 tail>     <UTF8 tail>
                | [\x{F1}-\x{F3}]     <UTF8 tail>     <UTF8 tail>     <UTF8 tail>
                |        [\x{F4}] [\x{80}-\x{8F}]     <UTF8 tail>     <UTF8 tail>
<UTF8 tail>     ~ [\x{80}-\x{BF}]
