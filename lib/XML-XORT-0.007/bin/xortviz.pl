#!/usr/local/bin/perl

use GraphViz;
use Data::Stag qw(:all);
#use Bio::XML::Sequence::Transform;
use Getopt::Long;

use FileHandle;
use strict;
use Data::Dumper;

my @valid_fmts = qw(png gd pic ps gd mif pcl gd2 jpeg vrml svg);

my $out;
my @conf_files;
my $fmt = 'png';
my $view;
my %graphvizopts = ();
my $fontsize = 10;

GetOptions(
           "help|h"=>sub{system("perldoc $0");exit 0},
           "out|o=s"=>\$out,
           "conf|c=s@"=>\@conf_files,
           "to=s"=>\$fmt,
           "view|v"=>\$view,
           "gv=s%"=>\%graphvizopts,
           "fontsize=s"=>\$fontsize,
          );

#my %stylesubs = ();
#my $m = "style_$style";
#no strict 'refs';
#%stylesubs = $m->();

my @font_args = ();
push(@font_args, "fontsize"=>$fontsize) if $fontsize;

my @conf_stags = ();
foreach my $conf (@conf_files) {
    push(@conf_stags,Data::Stag->parse($conf));
}

my $user_data_s;
while (my $fn = shift @ARGV) {
    my @pa = (-file=>$fn);
    if ($fn eq '-') {
        @pa = (-fh=>\*STDIN);
    }
    my $s = Data::Stag->parse(@pa);
    if ($s->name eq 'xortviz') {
        push(@conf_stags, $s);
    }
    else {
        if ($user_data_s) {
            die "maximum one data file! Cannot process $fn";
        }
        else {
            $user_data_s = $s;
        }
    }
}

# merge all confs into one
my $conf_s = Data::Stag->new(xortviz=>[map {$_->subnodes} @conf_stags]);


my %graph_opt_h = gv_opt_h($conf_s);
#my $g = GraphViz->new(rankdir=>$horizontal, %graphvizopts);
my $g = GraphViz->new(%graph_opt_h);

my @node_types = $conf_s->get_node;
foreach my $node_type (@node_types) {
    my $elt = $node_type->sget('@/element');
    debug("Getting nodes of type '%s'",$elt);
    my $pk = $node_type->sget('@/pk');
    # convert <opt> attributes to a hash
    my %opt_h = gv_opt_h($node_type);
    #my @nodes = $user_data_s->find($elt);
    my @nodes = $user_data_s->where($elt,sub{1});
    debug("Total $elt elements='%d'",scalar(@nodes));
    my %done_h = ();
    foreach my $node (@nodes) {
        #push(@nodes, $node->find($elt));   # recursive find
        my $pkval = make_id($node);
        next if $done_h{$pkval};
        $done_h{$pkval}=1;
        debug("Found $elt, id='%s'",$pkval);
        my $label = get_label($node_type,$node);
        $g->add_node($pkval,
                     label=>$label,
                     %opt_h);
        foreach my $subnode ($node->subnodes) {
            my $name = $subnode->name;
            my ($arc_type) = 
              $conf_s->where('arc',
                                sub {shift->sget('@/element') eq $name});
            if ($arc_type) {
                my $to = $arc_type->sget('@/to');
                my $tonode = $to eq '.' ? $subnode : $subnode->sget($to);
                # may be either a xort macro or a composite node..
                my $toval;
                if (ref($tonode)) {
                    if ($tonode->isterminal) {
                        $toval = $tonode->data;
                    }
                    else {
                        my @data_elements = $tonode->subnodes;
                        $toval = make_id($data_elements[0]);
                    }
                }
                else {
                    $toval = $tonode;
                }
                if (!$toval) {
                    die "in $pkval/$name, no toval found for $to; node=$tonode";
                }
                debug("arc $name => $toval");
                my $label = get_label($arc_type,$subnode);
                my %arc_opt_h = gv_opt_h($arc_type);
                $g->add_edge($toval,$pkval,
                             label=>$label,
                             %arc_opt_h);
            }
        }
    }
}


my $ofh = \*STDOUT;
my $is_out_a_tempfile;
if ($view && !$out) {
    $is_out_a_tempfile = 1;
    $out = $$.".tmp.$fmt";
}
if ($out) {
    if ($out =~ /\.(w+)$/) {
        my $nu_fmt = $1;
        if (grep {$nu_fmt eq $_} @valid_fmts) {
            $fmt = $nu_fmt;
        }
    }
    $ofh = FileHandle->new(">$out") || die($out);
}
my $meth = 'as_'.$fmt;
print $ofh $g->$meth();
$ofh->close if $out;
if ($view) {
    system("display $out");
}

# done!
exit 0;

END {
    if ($is_out_a_tempfile) {
        unlink($out);
    }
}


# --

sub get_label ($$) {
    my $node_type = shift;
    my $node = shift;
    my $label_s = $node_type->sget_label;
    if (!$label_s) {
        return '';
    }
    my $label = '';
    foreach my $label_part ($label_s->subnodes) {
        if ($label_part->name eq 'copy') {
            my $l_elt = $label_part->sget('@/element');
            $label .= $node->sget($l_elt);
        } 
        elsif ($label_part->name eq 'text') {
            $label .= $label_part->data;
        } 
        elsif ($label_part->name eq 's') {
            my $re = $label_part->data;
            my $cmd = "\$label =~ s$re";
            eval $cmd;
        } 
        else {
            die("label_part ". $label_part->xml);
        }
    }
    return $label;
}

sub gv_opt_h ($) {
    my $node_type = shift;
    my %opt_h = @font_args;

    my @gv_opts = $node_type->get('opts');
    foreach (@gv_opts) {
        my $att_s = $_->sget('@');
        if ($att_s) {
            foreach ($att_s->subnodes) {
                $opt_h{$_->name} = $_->data;
            }
        }
    }
    return %opt_h;
}

sub make_id ($) {
    my $s = shift;
    my $id;
    if (ref($s)) {
        $id = $s->sget('@/id');
        if (!$id) {
            my $elt = $s->name;
            my ($table_s) = $conf_s->where('table',
                                           sub {shift->sget('@/id') eq $elt});
            die "I need a table def for $elt" unless $table_s;
            my $u = $table_s->sget_unique;
            $id = '';
            if ($u) {
                my @cols = $u->get_col;
                my @sub_ids = ();
                foreach my $col_s (@cols) {
                    my $col_name = $col_s->sget('@/name');
                    push(@sub_ids,make_id($s->sget($col_name)));
                }
                $id = join('__',@sub_ids);
            } else {
                die "I need a unique key def for $elt";
            }
        }
    } 
    else {
        $id= $s;
    }
    return $id;
}

sub debug {
    my $fmt = shift;
    printf STDERR "# $fmt\n", @_
}

__END__

=head1 NAME

xortviz.pl   -- visualise XORT-conformant XML files (e.g. Chado-XML)

=head1 SYNOPSIS

 xortviz.pl -c conf/xv-chado.xml MSGEFTUA.chado -o pic.png  
 xortviz.pl conf/xv-*.xml MSGEFTUA.chado -o pic.dot  

=head1 DESCRIPTION

Produce graphviz diagrams of XML files. Diagrams can be exported in
formats such as PNG, or exported to dot format (and can be imported
into diagramming tools such as OmniGraffle)

The xortviz script itself is fairly lightweight and has no knowledge
of any domain specific XML formats. All the logic is in the XML conf
files, which specify a mini-language for rendering XML nodes and
node-nesting as graohviz nodes and arcs

=head2 ARGUMENTS

=head3 -c CONF-FILE

An XML conf file. Conf files can be combined by specifying this option
multiple times

 xortviz.pl -c xviz-feature.xml -c xviz-organism.xml my.chado | display -

In actual fact, this script is smart enough to determine which files
are comnmf files and which are data files, provided the conf files all
have xortviz as the root element. This means you can dispense with the
-c option, which is nice if you have a lot of conf files.

Conf files can be mixed and matched for different effects. For
example, with chado-xml conf files, you can choose whether to show
features, features+feature_relationships, features+organsims,
features+featurelocs or whatever combo you like:

 xortviz.pl conf/xv-feature.xml my.chado 
 xortviz.pl conf/xv-feature.xml conf/xv-organism.xml my.chado 

=head3 -o OUT-FILE

defaults to stdout

=head3 -to FORMAT

defaults to PNG.

Options are: png gd pic ps gd mif pcl gd2 jpeg vrml svg

See L<GraphViz> for more details

=head3 -v

View the results directly using ImageMagick 'display' program

=head2 EXAMPLE FILES

See the xort conf dir for example configurations

See chado/modules/sequence/examples for data files

=head1 XML CONFIGURATION LANGUAGE

More details to follow. Please see example configurations for details

=head2 Elements

=head3 opts

attributes are passed directly to graphviz. This element can appear as
a top-level element (it applies to the graph), or as a node or arc
element. See GraphViz for details

Example:

  <opts shape='ellipse' style='filled' fillcolor='#FF8888' fontsize='10'
      fontname='arial'/>

=head3 node

top-level element. this specifies how an XML element in the data file
is to be rendered as a graph node

The name of the element is provided with the 'element' attribute.

The 'pk' attribute specifies what the primary key is for this
node. See key info

Example:

  <node element="feature" pk=".">
    <opts shape='ellipse' style='filled' fillcolor='#FF8888' fontsize='10'
      fontname='arial'/>
    <label>
      <copy element="name"/>
      <text>[</text>
      <copy element="type_id"/>
      <s>/sequence__//</s>
      <text>]</text>
    </label>
  </node>

=head3 arc

top-level element. this specifies how an XML element in the data file
is to be rendered as a graph arc

The arc element is assumed to be embedded inside a node element (the
source node)

The 'to' attribute specifies the element or element path to follow to
obtain the node at the end of the arc (the sink node)

Example:

  <arc element="featureloc" to="srcfeature_id">
    <opts style='dashed' arrowhead='dot' 
      decorateP='1' fontcolor='#0000FF' color='#0000FF'/>
    <label>
      <copy element="fmin"/>
      <text>..</text>
      <copy element="fmax"/>
    </label>
  </arc>

=head3 label

This element can appear under the node or arc element. It specifies
how to construct a node or arc label by concatenating canned text,
data elements and regular expressions

Sub-elements are copy, text and s

copy specifies a stag-path to the data

text is canned text

s is a perl s/// expression

Example:

    <label>
      <copy element="genus"/>
      <text>-</text>
      <copy element="species"/>
      <text>[</text>
      <copy element="organism_dbxref/dbxref_id/dbxref/accession"/>
      <text>]</text>
    </label>

=head3 table

metadata on a data element (aka table). Can be used to provide a
unique key constraint on a data element

Example:

  <table id="feature">
    <unique>
      <col name="organism_id"/>
      <col name="uniquename"/>
      <col name="type_id"/>
    </unique>
  </table>


=head2 Keys

This script works best with XORT-generated XML. It has built-in
knowledge of how XORT macros work (but no built in knowledge of
Chado-XML).

With XORT XML, data elements can appear multiple places in the
XML. They are uniquely identified by the underlying relational
uniqueness constraints. Or they can be identified by XORT
macros. xortviz *should* be able to resolve all these

=head1 REQUIREMENTS

L<Data::Stag>

L<GraphViz>

=head1 AUTHOR

Chris Mungall

 cjm AT fruitfly DOT org

=cut
