package Sledge::TestPages;
# $Id$
#
# Tatsuhiko Miyagawa <miyagawa@edge.co.jp>
# Livin' On The EDGE, Co., Ltd..
#

use strict;
use vars qw($VERSION);
$VERSION = '0.01';

use Sledge::Pages::Compat;
use Sledge::Authorizer::Null;
use Sledge::SessionManager::Cookie;
use Sledge::Charset::Default;
use Sledge::Template::TT;
use IO::Scalar;

$ENV{HTTP_HOST}    = 'localhost';
$ENV{REQUEST_URI}  = '/';
$ENV{QUERY_STRING} = '';

sub create_authorizer {
    my $self = shift;
    return Sledge::Authorizer::Null->new($self);
}

sub create_manager {
    my $self = shift;
    return Sledge::SessionManager::Cookie->new($self);
}

sub create_charset {
    my $self = shift;
    return Sledge::Charset::Default->new($self);
}

sub create_config {
    my $self = shift;
    return Sledge::TestConfig->new($self);
}

sub create_session {
    my $self = shift;
    return Sledge::TestSession->new($self, @_);
}

sub dispatch {
    my $self = shift;
    CGI::initialize_globals();
    tie *STDOUT, 'IO::Scalar', \my $out;
    $self->SUPER::dispatch(@_);
    untie *STDOUT;
    bless $self, __PACKAGE__;
    $self->{output} = $out;
}

sub output { shift->{output} }

package Sledge::TestConfig;
use vars qw($AUTOLOAD);

sub new {
    my($class, $proto) = @_;
    bless { pkg => ref $proto || $proto }, $class;
}

sub DESTROY { }

sub AUTOLOAD {
    my $self = shift;
    my $pkg = $self->{pkg};
    (my $method = $AUTOLOAD) =~ s/.*://;
    no strict 'refs';
    my $val = ${"$pkg\::" . uc($method)};
    return (ref($val) eq 'ARRAY' && wantarray) ? @$val : $val;
}

package Sledge::TestSession;
use base qw(Sledge::Session);

sub _connect_database    { }
sub _commit              { }
sub _do_lock             { }
sub _lockid              { }

my %session;
sub _select_me {
    my $self = shift;
    $self->{_data} = $session{$self->session_id};
}

sub _insert_me {
    my $self = shift;
    $session{$self->session_id} = $self->{_data};
}

sub _update_me {
    my $self = shift;
    $session{$self->session_id} = $self->{_data};
}

sub _delete_me {
    my $self = shift;
    delete $session{$self->session_id};
}

1;

1;
__END__

=head1 NAME

Sledge::TestPages - Mock object for Sledge Testing

=head1 SYNOPSIS

  package Mock::Pages;
  use base qw(Sledge::TestPages);
  use Sledge::Template::TT;

  sub dispatch_name {
      my $self = shift;
      $self->session->param(var => 'value');
      ::isa_ok $self->tmpl->param('session'), 'Sledge::Session';
      ::isa_ok $self->tmpl->param('r'), 'Sledge::Request::CGI';
      ::isa_ok $self->tmpl->param('config'), 'Sledge::TestConfig';
  }

  package main;
  $ENV{HTTP_HOST}      = "localhost";
  $ENV{REQUEST_URI}    = "http://localhost/name.cgi";
  $ENV{REQUEST_METHOD} = 'GET';
  $ENV{QUERY_STRING}   = 'name=miyagawa';

  my $d = $Mock::Pages::TMPL_PATH;
  $Mock::Pages::TMPL_PATH = "t/template";
  my $page = Mock::Pages->new;
  $page->dispatch('name');

  my $out = $page->output;
  like $out, qr/name is miyagawa/;
  like $out, qr/session var is value/;

=head1 DESCRIPTION

Sledge::TestPages is a base class for Mock Object that can be used in
Testing Sledge web applications.

=head1 REQUEST ENVIRONMENTS

With Sledge::TestPages, your Pages class runs in CGI-mode. thus you
should supply environment variables to setup URL, HTTP_HOST etc.

  $ENV{HTTP_HOST}      = "localhost";
  $ENV{REQUEST_URI}    = "http://localhost/name.cgi";
  $ENV{REQUEST_METHOD} = 'GET';
  $ENV{QUERY_STRING}   = 'name=miyagawa';

=head1 CONFIGURATION VARIABLES

Configuration variables can be fetched via package variable of your
Pages class. For example, C<TMPL_PATH> variable can be set as:

  $Mock::Pages::TMPL_PATH = "t/template";

See C<AUTOLOAD> method in Sledge::TestConfig for details.

=head1 CAPTURING OUTPUT

After you call C<dispatch> method, page output is captured in
$page->output. You just call C<like> of Test::More to test the output.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@livedoor.jpE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Sledge.

=head1 SEE ALSO

L<Sledge>

=cut
