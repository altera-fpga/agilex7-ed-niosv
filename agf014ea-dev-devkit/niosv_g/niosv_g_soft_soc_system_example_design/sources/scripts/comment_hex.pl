#!/usr/bin/perl
use strict;
use warnings;
use File::Copy;

# Check for input argument
if (@ARGV != 1) {
    die "Usage: perl disable_hex_by_path.pl <path/to/CMakeLists.txt>\n";
}

my $filename = $ARGV[0];

unless (-f $filename) {
    die "File '$filename' does not exist.\n";
}

my $backup = $filename . '.bak';

print "Processing $filename...\n";

# Backup the original CMakeLists.txt
move($filename, $backup) or die "Cannot create backup for $filename: $!";

open my $in,  '<', $backup   or die "Cannot open $backup: $!";
open my $out, '>', $filename or die "Cannot open $filename: $!";

my $inside_command = 0;
my @buffer = ();
my $should_comment = 0;

while (my $line = <$in>) {
    # Detect start of add_custom_command
    if (!$inside_command && $line =~ /^\s*add_custom_command\s*\(/) {
        $inside_command = 1;
        @buffer = ($line);
        $should_comment = 0;
        next;
    }
    if ($inside_command) {
        push @buffer, $line;
        # Check for OUTPUT ".hex" in this line
        if ($line =~ /OUTPUT\s+"[^"]+\.hex"/) {
            $should_comment = 1;
        }
        # End of block
        if ($line =~ /^\s*\)/) {
            # Print and comment if needed
            if ($should_comment) {
                foreach my $bufline (@buffer) {
                    print $out "# $bufline";
                }
            } else {
                foreach my $bufline (@buffer) {
                    print $out $bufline;
                }
            }
            $inside_command = 0;
            @buffer = ();
            $should_comment = 0;
        }
        next;
    }
    # Comment out create-hex custom target
    if ($line =~ /^\s*add_custom_target\s*\(\s*create-hex\s+ALL\s+DEPENDS/) {
        print $out "# $line";
        next;
    }
    # Print all other lines
    print $out $line;
}

close $in;
close $out;

print "  -> .hex file generation commands commented out in $filename.\n";
