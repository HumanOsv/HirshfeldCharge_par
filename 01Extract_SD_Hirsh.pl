#usr/bin/perl

use strict;
use warnings;
use Benchmark; # entrega cuando demora el proceso, cuanto de CPU utilizó, etc
#


sub VMD {
    my ($arr,$sd,$filename) = @_;
    #
    open(my $fh, '>', "VMD-$filename.vmd") or die "Could not open file '$filename' $!";
    print $fh "draw delete all\n";
	print $fh "draw materials off\n";
	print $fh "draw color green\n";
    print $fh "display projection Orthographic\n";
	print $fh "display depthcue off\n" ;
	print $fh "axes location off\n"; 
	#
    my @spin = @{$sd};
    my @tam = @{$arr};
	for ( my $i = 0 ; $i < 4 ; $i++ ){
        my @tmp = ();
        @tmp =  split (/\s+/,$tam[$i]);
	   print $fh "draw text \"$tmp[0] $tmp[1] $tmp[2]\" \" $spin[$i]\" size \"2\" thickness \"2\" \n";
    }
    close $fh;
}




my $tiempo_inicial = new Benchmark; #funcion para el tiempo de ejecucion del programa
#
# Modo de uso
my ($tempf) = ($0 =~ m<([^\\/]+?\.log)$>i);
#
#my $input_file    = $ARGV[0];

my ($input_file) = @ARGV;
if (not defined $input_file) {
	die "\nHirsh SD must be run with:\n\nUsage:\n\tperl 01Extract_SD_Hirsh.pl filename.log|.out\n\n\n";
	exit(1);
}

# leer directorio solo los archivos .out o .log
my @array_energy = ();
my @array_coords = ();
my @array_files  = ();

my @columns_4N = ();
# numero de atomos
my $atom_numb;
#
#############
# Main
my @Secuencias = ();
# coodenadas
my @coords;
# energia
my $energy;
my $zero_point;
#
my @spin_den      = ();
my @spin_den_atom = ();
my @total_coords  = ();
my @total_coords_atoms = ();
                
my $file = $input_file;
my $seqlinea;
# # # #
        open (IN, "<$file")||die "cannot open $file in readseq subroutine:$!\n";
        while ($seqlinea = <IN>) {
                chomp($seqlinea);
                push (@Secuencias, $seqlinea);
        }
        close IN;
        #
        my @columns_1N = ();
        my @columns_2N = ();
        my @columns_3N = ();
        #
        my $count_lines = 0;
        #
        foreach my $a_1 (@Secuencias){
                # SCF Done:  E(RPBE1PBE) =  -56.7829127857     A.U. after   40 cycles
                if ( ($a_1=~/SCF/gi ) && ($a_1=~/Done/gi ) && ($a_1=~/after/gi ) ){
                        my @array_tabs = ();
                        #
                        @array_tabs = split (/ /,$a_1);
                        #
                        push (@columns_1N  ,$array_tabs[7]);
                }
                # Standard orientation:
                if ( ($a_1=~/Standard/gi ) && ($a_1=~/orientation/gi ) && ($a_1=~/:/gi ) ){
                        #
                        push (@columns_2N  ,$count_lines);
                }
                # Rotational constants (GHZ):
                if ( ($a_1=~/Rotational/gi ) && ($a_1=~/constants/gi ) && ($a_1=~/GHZ/gi ) ){
                        #
                        push (@columns_3N  ,$count_lines);
                }
                # Hirshfeld charges, spin densities, dipoles, and CM5 charges using IRadAn
                if ( ($a_1=~/Hirshfeld/gi ) && ($a_1=~/spin/gi ) && ($a_1=~/dipoles/gi ) && ($a_1=~/charges/gi ) && ($a_1=~/IRadAn/gi ) ){
                        #
                        push (@columns_4N  ,$count_lines);
                }
				#
                $count_lines++;
        }
        #
        if ( scalar (@columns_1N) > 0 ){
                for (my $i=0; $i < scalar (@columns_1N); $i++){
                        #
                        my $start = $columns_2N[$i] + 5;
                        my $end   = $columns_3N[$i] - 2;
                        $atom_numb = $end - $start + 1;
                        #
                        $energy     = $columns_1N[$i];
                        #
                        @coords = ();
                        foreach my $j (@Secuencias[$start..$end]){
                                push (@coords,$j);
                        }
                }
                #

                foreach my $i (@coords){
                    my @tmp = ();
                    @tmp =  split (/\s+/,$i);
                    push (@total_coords,"$tmp[4]  $tmp[5]  $tmp[6]");
                    push (@total_coords_atoms,"$tmp[2]");
                }
                push(@array_energy,$energy);
                push(@array_coords,[@total_coords]);
                push(@array_files,$input_file);
                #
                my $start_Hirsh = $columns_4N[0] + 2;
                my $end_Hirsh   = ($columns_4N[0] + $atom_numb) + 1;
                foreach my $j (@Secuencias[$start_Hirsh..$end_Hirsh]){
                    my @tmp = ();
                    @tmp =  split (/\s+/,$j);
                    push (@spin_den,$tmp[4]);
                    push (@spin_den_atom,"$tmp[2]$tmp[1]");
                }
        #
        } else {
                print "No presenta SCF: $input_file\n";
        }



# sort, same thing in reversed order
my @value_SD_sort = ();
my @value_coords_sort = ();
my @value_Atoms_sort = ();
my @idx = sort { $spin_den[$b] <=> $spin_den[$a] } 0 .. $#spin_den;
@value_SD_sort     = @spin_den[@idx];
@value_coords_sort = @total_coords[@idx];
@value_Atoms_sort  = @spin_den_atom[@idx];

print "\n\nAtom\tSpin Density\tAxis X\tAxis Y\tAxis Z\n";
print "\n";
for (my $i=0; $i < scalar (@value_SD_sort); $i++){
    print "$value_Atoms_sort[$i]\t$value_SD_sort[$i]\t$value_coords_sort[$i]\n";
}
#
my $filename = "$input_file.xyz";
open(my $fh, '>', $filename) or die "Could not open file '$filename' $!";
print $fh "$atom_numb\n";
print $fh "$input_file\n";
for (my $i=0; $i < scalar (@total_coords); $i++){
    print $fh "$spin_den_atom[$i]  $total_coords[$i]\n";
}
close $fh;


VMD (\@value_coords_sort,\@value_SD_sort,$input_file);
  

##############################################################
my $tiempo_final = new Benchmark;
my $tiempo_total = timediff($tiempo_final, $tiempo_inicial);
print "\n\tTiempo de ejecucion: ",timestr($tiempo_total),"\n";
print "\n";

