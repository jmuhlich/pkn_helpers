#!/usr/bin/perl

use strict;
use XML::Twig;

# magic scaling to make the units come out right
use constant
{
  SIZE_SCALE => 1/72, # probably based on 72 DPI
  FONT_SCALE => 2,    # XXX Promot apparently doesn't export real font
                      # sizes to gxl so the font sizes are bogus
                      # anyway. this is hack to make this file work.
  LABEL_CUTOFF => 20, # XXX width cutoff below which we hide labels
};

sub normalize_id;
sub normalize_color;
sub quote;

my @nodes;
my @edges;
my $cur_node;
my $cur_edge;

my %shape_map =
  (
   diamond        => 'diamond',
   ellipse        => 'ellipse',
   hexagon        => 'hexagon',
   roundrectangle => 'box',
  );

my $twig = XML::Twig->new
  (
   start_tag_handlers =>
   {
    'node'          => \&parse_node,
   },
   twig_handlers =>
   {
    'node'          => \&print_node,
    'y:Geometry'    => \&parse_geometry,
    'y:Fill'        => \&parse_fill,
    'y:BorderStyle' => \&parse_borderstyle,
    'y:NodeLabel'   => \&parse_nodelabel,
    'y:Shape'       => \&parse_shape,
   },
  );
print "digraph {\n";
$twig->parsefile($ARGV[0]);
print "}\n";


sub parse_node
{
  $cur_node = { id => normalize_id($_[1]->att('id')) };
  push @nodes, $cur_node;
}


sub parse_geometry
{
  $cur_node->{fixedsize} = 'true';
  $cur_node->{height}    = $_[1]->att('height') * SIZE_SCALE;
  $cur_node->{width}     = $_[1]->att('width') * SIZE_SCALE;
  # yfiles positions by corner, graphviz positions by center
  my $x = $_[1]->att('x') + $_[1]->att('width') / 2;
  # also, the Y axis is flipped
  my $y = -( $_[1]->att('y') + $_[1]->att('height') / 2 );
  $cur_node->{pos}       = quote "$x,$y" ;
}


sub parse_fill
{
  $cur_node->{fillcolor} = quote normalize_color $_[1]->att('color');
  $cur_node->{style}     = 'filled';
  # transparency? (unsupported in graphviz)
}


sub parse_borderstyle
{
  $cur_node->{color} = quote normalize_color $_[1]->att('color');
  # type? (only see "line" in this one sample file)
  # width? (unsupported in graphviz)
}


sub parse_nodelabel
{
  if ( $_[1]->att('width') >= LABEL_CUTOFF )
  {
    $cur_node->{label} = quote $_[1]->text;
  }
  else
  {
    $cur_node->{label} = quote '';
  }
  $cur_node->{fontsize} = $_[1]->att('fontSize') * FONT_SCALE;
  $cur_node->{fontcolor} = quote normalize_color $_[1]->att('textColor');
  $cur_node->{fontname} = quote $_[1]->att('fontFamily');
  # height/width appear to be the same as Geometry[height,width]
  # x has no obvious significance
  # attributes with only one value in this sample file:
  #   alignment=top, autoSizePolicy=content fontStyle=plain
  #   hasBackgroundColor=false modelName=internal modelPosition=c
  #   visibility=true
}


sub parse_shape
{
  my $type = $_[1]->att('type');
  $cur_node->{shape} = $shape_map{$type};
  defined $cur_node->{shape} or die "No mapping for shape type '$type' (edit \%shape_map)";
}


sub print_node
{
  print delete $cur_node->{id};
  print ' [';
  print join(', ', map("$_=$cur_node->{$_}", keys %$cur_node));
  print "]\n";
}


sub normalize_id
{
  my $id = pop;
  $id =~ tr/-://d;
  return $id;
}


sub normalize_color
{
  return '#' . '0' x (7 - length($_[0])) . substr($_[0], 1);
}

sub quote
{
  return qq{"$_[0]"};
}
