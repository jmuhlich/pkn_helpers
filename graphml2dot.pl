#!/usr/bin/perl

use strict;
use XML::Twig;

# magic scaling to make the units come out right
use constant
{
  SIZE_SCALE => 1/72, # positions are in points, but sizes aren't?
  FONT_SCALE => 2,    # XXX Promot apparently doesn't export real font
                      # sizes to gxl so the font sizes are bogus
                      # anyway. this is hack to make this file work.
  EDGE_SCALE => 3,    # line thickness
  LABEL_CUTOFF => 20, # XXX width cutoff below which we hide labels
};

sub normalize_id;
sub normalize_color;
sub quote;

my @nodes;
my @edges;
my $cur_node;
my $cur_edge;
my %oldid_to_newid;
my %edge_weights;


my %shape_map =
  (
   diamond        => 'diamond',
   ellipse        => 'ellipse',
   hexagon        => 'hexagon',
   roundrectangle => 'box',
  );

my %style_map =
  (
    line          => 'solid',
    dashed        => 'dashed',
  );

# path to skip over the top-level single-node graph, as the nodes we
# really want are nested in the subgraph.  edges are all at the top
# level so no path is needed there. y: elements on the top-level graph
# node do end up getting parsed but are never printed.
my $np = '/graphml/graph/node/graph';

my $twig = XML::Twig->new
  (
   start_tag_handlers =>
   {
    "$np/node"      => \&parse_node,
    'edge'          => \&parse_edge,
   },
   twig_handlers =>
   {
    "$np/node"      => \&print_node,
    'edge'          => \&print_edge,
    'y:Geometry'    => \&parse_geometry,
    'y:Fill'        => \&parse_fill,
    'y:BorderStyle' => \&parse_borderstyle,
    'y:NodeLabel'   => \&parse_nodelabel,
    'y:Shape'       => \&parse_shape,
    'y:LineStyle'   => \&parse_linestyle,
    'y:Arrows'      => \&parse_arrows,
   },
  );
print "digraph \"g\" {\n";
print "graph [splines=true]\n";
$twig->parsefile($ARGV[0]);
print "}\n";


#==========


sub parse_node
{
  $cur_node = { __oldid => $_[1]->att('id') };
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
  $cur_node->{fillcolor} = normalize_color $_[1]->att('color');
  $cur_node->{style}     = 'filled';
  # transparency? (unsupported in graphviz)
}


sub parse_borderstyle
{
  $cur_node->{color} = normalize_color $_[1]->att('color');
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
  $cur_node->{id} = normalize_id $_[1]->text;
  $cur_node->{fontsize} = $_[1]->att('fontSize') * FONT_SCALE;
  $cur_node->{fontcolor} = normalize_color $_[1]->att('textColor');
  $cur_node->{fontname} = quote $_[1]->att('fontFamily');
  $oldid_to_newid{$cur_node->{__oldid}} = $cur_node->{id};
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


#==========


sub parse_edge
{
  my $source = $oldid_to_newid{$_[1]->att('source')};
  my $target = $oldid_to_newid{normalize_id $_[1]->att('target')};
  $cur_edge = { source => $source, target => $target };
}


sub parse_linestyle
{
  $cur_edge->{color} = normalize_color $_[1]->att('color');
  $cur_edge->{penwidth} = $_[1]->att('width') * EDGE_SCALE;
  $cur_edge->{style} = $style_map{$_[1]->att('type')};
}


sub parse_arrows
{
  # XXX are any values other than 'none' and 'standard' used?
  my $source = $_[1]->att('source') eq 'standard';
  my $target = $_[1]->att('target') eq 'standard';
  my $dir;
  if    ( $source and $target) { $cur_edge->{dir} = 'both'      }
  elsif ( $source )            { $cur_edge->{dir} = 'back'      }
  elsif ( $target )            { $cur_edge->{dir} = 'forward'   }
  else                         { $cur_edge->{dir} = 'forward';
                                 $cur_edge->{arrowhead} = 'tee' }
}


#==========


sub print_node
{
  print delete $cur_node->{id};
  print ' [';
  print join(', ', map("$_=$cur_node->{$_}", grep {!/^__/} keys %$cur_node));
  print "]\n";
}


sub print_edge
{
  print join(' -> ', delete @$cur_edge{qw(source target)});
  print ' [';
  print join(', ', map("$_=$cur_edge->{$_}", grep {!/^__/} keys %$cur_edge));
  print "]\n";
}


#==========


sub normalize_id
{
  my ($id) = @_;
  $id =~ tr/\W/_/d;
  return $id;
}


sub normalize_color
{
  return quote( '#' . '0' x (7 - length($_[0])) . substr($_[0], 1) );
}

sub quote
{
  return qq{"$_[0]"};
}
