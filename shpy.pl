#!/usr/bin/perl -w

### -------------------------------------------- ###
###	This assignment is written by Mengxin Huang  ###
###	            Student ID: z5013846             ###
### -------------------------------------------- ###

# read from shell script, translate it to python

#first, check to import Python modules
$flag_1 = 0;
$flag_2 = 0;
$flag_3 = 0;
$flag_4 = 0;
$flag_5 = 0;
$flag_6 = 0;
$flag_7 = 0;
$flag_8 = 0;
open FILE, ">tempfile" or die "cannot open file";
while($line = <STDIN>) {
	print FILE "$line";
	if($line =~ /\#\!\/bin\/bash/ and $flag_1 == 0) {
		print  "#!/usr/bin/python2.7 -u\n";
		$flag_1 = 1;
	}
	elsif(($line =~ /test \-d/i or $line =~ /\[ \-d/i)and $flag_5 == 0) {
		print  "import os.path\n";
		$flag_5 = 1;
	}
	elsif(($line =~ /test \-r/i or $line =~ /\[ \-r/i)and $flag_6 == 0) {
		print  "import os\n";
		$flag_6 = 1;
	}
	elsif(($line =~ /ls[ \`][^\-]/ or $line =~ /ls \-l[ \`]/) and $flag_7 == 0 and $flag_3 == 0) {
		print  "import subprocess\n";
		$flag_7 = 1;
	}
	elsif($line =~ /ls \-las/ and $flag_8 == 0) {
		if($flag_7 == 1 or $flag_3 == 1) {
			print  "import sys\n";
			$flag_8 = 1;
		}
		if($flag_7 == 0 and $flag_3 == 0) {
			print  "import subprocess\n";
			print  "import sys\n";
			$flag_8 = 1;
		}
	}
	else {
		@words = split(/ /, $line);
		foreach $word (@words) {
			if($word =~ /^cd$/i and $flag_2 == 0) {
				print  "import os\n";
				$flag_2 = 1;
			}
			if(($word =~ /^[\`]?pwd[\`]?$/i or $word =~ /^[\`]?id[\`]?$/i or $word =~ /^[\`]?date[\`]?$/i) and $flag_3 == 0 and $flag_7 == 0) {
				print  "import subprocess\n";
				$flag_3 = 1;
			}
			if(($word =~ /^exit$/ or $word =~ /^read$/ or $word =~ /\$[\#\*\@0-9]+/) and $flag_4 == 0 and $flag_8 == 0) {
				print  "import sys\n";
				$flag_4 = 1;
			}
		}
	}
}
close FILE;

#start translating Shell to Python
$temp = "";
$tab = 0;
open FILE, "<tempfile" or die "cannot open file";
while($line = <FILE>) {

	### delete tab at the beginning of a line ###
	$line =~ s/^[ \t]+//gi;

	### translate comments ###
	if($line =~ /^\# .*/) {
		print  "$line";
		next;
	}

	### translate builtins ###
	# there are 4 types of builtins
	# type 1: ls, pwd, id and date
	# type 2: cd
	# type 3: exit
	# type 4: read
	$builtin_type = 0;
	if($line =~ /[^a-zA-Z]*ls[^a-zA-Z]/ or $line =~ /[^a-zA-Z]*pwd[^a-zA-Z]/ or $line =~ /[^a-zA-Z]*id[^a-zA-Z]/ or $line =~ /[^a-zA-Z]*date[^a-zA-Z]/) {
		if($line =~ /^echo/) {
			;
		}
		else {
			$builtin_type = 1;
			builtin($line);
		}
	}
	if($line =~ /[^a-z]*cd[^a-z]*/) {
		$builtin_type = 2;
		builtin($line);
	}
	if($line =~ /exit [01]/) {
		$builtin_type = 3;
		builtin($line);
	}
	if($line =~ /read [a-zA-Z0-9_]+/) {
		$builtin_type = 4;
		builtin($line);
	}

	### translate for loop ### 
	if($line =~ /for [A-Za-z0-9_]+ in/) {
		for_loop($line);
	}

	### check tab ###
	if($line =~ /^then[ \r\n]$/ or $line =~ /^do[ \r\n]$/) {
		$tab++;
	}
    if($line =~ /^fi[ \r\n]$/ or $line =~ /^done[ \r\n]$/ or $line =~ /^elif test/i or $line =~ /^else[ \r\n]$/) {
       	$tab--;
    }
	
	### translate if statement ###
	# there are 3 types of if statements
	$if_type = 0;
	# type 1: if test or if []...
	if($line =~ /^if test [^\-]/ or $line =~ /^if \[ [^\-]/ or $line =~ /^elif test [^\-]/ or $line =~ /^elif \[ [^\-]/) {			
		$if_type = 1;
		if_if($line);
	}
	# type 2: if test -r...
	if($line =~ /^if test \-r/ or $line =~ /^if \[ \-r/ or $line =~ /^elif test \-r/ or $line =~ /^elif \[ \-r/) {			
		$if_type = 2;
		if_if($line);
	}
	# type 3: if test -d ...
	if($line =~ /^if test \-d/ or $line =~ /^if \[ \-d/ or $line =~ /^elif test \-d/ or $line =~ /^elif \[ \-d/) {			
		$if_type = 3;
		if_if($line);  
	}
	# else
	if($line =~ /^else[ \r\n]+$/) {
		print  "else:\n";
		$tab++;
	}

	### translate while loop ###
	# there are 2 types of while loop
	$while_type = 0;
	# type 1: while true
	if($line =~ /^while true/) {
		$while_type = 2;
		while_loop($line);
	}
	# type 2: while test or while [] ...
	if($line =~ /^while test/ or $line =~ /^while \[/) {
		$while_type = 1;
		while_loop($line);
	}

	### translate equation ###
	# there are 9 types of equations
	$eq_type = 0;
	# type 1: var=`expr ...`
	if($line =~ /[a-zA-Z][a-zA-Z0-9_]*\=\`expr .*\`/) {
		$eq_type = 1;
		equation($line);
	}
	# type 2: var=$((...))		
	if($line =~ /[a-z][a-z0-9_]*\=\$\(\(.*\)\)/i) {
		$eq_type = 2;
		equation($line);
	}
	# type 3: var=x+y which means string concat
	if($line =~ /[a-z][a-z0-9_]*\=[^ ]*[\+]+.*/i and $eq_type != 1 and $eq_type != 2) {
		$eq_type = 3;
		equation($line);
	}
	# type 4: var=hello
	if($line =~ /[a-z][a-z0-9_]*\=[a-z]+/i and $eq_type != 3) {
		$eq_type = 4;
		equation($line);
	}
	# type 5: var=$1
	if($line =~ /[a-z][a-z0-9_]*\=[\$][0-9]+/i and $eq_type != 3) {
		$eq_type = 5;
		equation($line);
	}
	# type 6: var=$a
	if($line =~ /[a-z][a-z0-9_]*\=[\$][a-z]+/i and $eq_type != 3) {
		$eq_type = 6;
		equation($line);
	}
	# type 7: var=1
	if($line =~ /[a-z][a-z0-9_]*\=[0-9]+/i and $eq_type != 3) {
		$eq_type = 7;
		equation($line);
	}
	# type 8: var='hello' 	
	if($line =~ /[a-z][a-z0-9_]*\=\'.*\'/i and $eq_type != 1 and $eq_type != 3) {
		$eq_type = 8;
		equation($line);
	}
	# type 9: var="hello"
	if($line =~ /[a-z][a-z0-9_]*\=\".*\"/i and $eq_type != 3) {
		$eq_type = 9;
		equation($line);
	}

	### translate echo ###
	# there are 6 types of echo
	$echo_type = 0;	
	$dashn = 0;
	$var = 0;
	$quote = 0;
	$cmd = 0;
	# type 6: echo `ls` echo `id` echo `date` echo `pwd`
	if($line =~ /echo \`ls.*\`/ or $line =~ /echo \-n \`ls.*\`/ or $line =~ /echo \`date\`/ or $line =~ /echo \-n \`date\`/ or $line =~ /echo \`pwd\`/ or $line =~ /echo \-n \`pwd\`/ or $line =~ /echo \`id\`/ or $line =~ /echo \-n \`id\`/) {
		$cmd = 1;
		$echo_type = 6;
		echo_print($line);
	}
	# type 5: echo `expr ...`
	if($line =~ /echo \`expr.*\`/ or $line =~ /echo \-n \`expr.*\`/) {
		$echo_type = 5;
		echo_print($line);
	}
	# type 4: echo mixed with single quotes and double quotes
	# type 3: echo with only double quotes, words with no quotes can appear 
	if($line =~ /echo.*".*"/ or $line =~ /echo +\-n.*".*"/) {
		$quote = 1;
		if($line =~ /'.*'/) {
			$echo_type = 4;
			echo_print($line);
		}
		else {
			$echo_type = 3;	
			echo_print($line);
		}
	}
	# type 2: echo with only single quotes, words with no quotes can appear
	if($line =~ /echo.*'.*'/ or $line =~ /echo \-n.*'.*'/) {
		$quote = 1;
		if($line =~ /".*"/) {
			;
		}
		elsif($line =~ /\`.*\`/) {
			;
		}
		else {
			$echo_type = 2;	
			echo_print($line);
		}
	}
	# type 1: echo with no quotes
	if(($line =~ /echo / or $line =~ /echo \-n/) and $quote == 0) {
		if($cmd == 1) {
			;
		}
		elsif($line =~ /\`.*\`/) {
			;
		}
		else {
			$echo_type = 1;
			echo_print($line);
		}
	}
		
	### an empty line ###
	if($line =~ /^[\r\n]$/) {
		print  "\n";
	}
}
close FILE;

# translate builtin function
sub builtin {
	$t = $tab;
	while($t > 0) {
		print  "\t";
		$t--;
	}
	@line = @_;	
	chomp @line;
	if($line[0] =~ /^ls \-las/) {
		$builtin_type = 5;
	}

	# store comments
	$str = "";
	@coms = split(/ /, $line[0]);
	if($line[0] =~ /[ \t]+#.*/) {
		$line[0] =~ s/[ \t]+#.*//g;
		$flag = 0;
		$str = "";
		foreach $com (@coms) {
			if($com =~ /^[\t]*#.*$/) {
				$flag = 1;
				$temp = " ";
				$str = $str.$com;
				$str = $str.$temp;
				next;
			}
			if($flag == 1) {
				$temp = " ";
				$str = $str.$com;
				$str = $str.$temp;
				next;
			}
		}
	}

	#subprocess.call(['ls', '-las'] + sys.argv[1:])
	if($builtin_type == 5) {
		@words = split(/ /, $line[0]);
		foreach $word (@words) {
			if($word =~ /\"\$@\"/) {
				$word = "sys.argv[1:]";
			}
			if($word =~ /\"\$[0-9]+\"/) {
				$word =~ s/[\$\"]//gi;
				$temp = "sys.argv[1]";
				$temp =~ s/1/$word/gi;
				$word = $temp;
			}
		}
		print  "subprocess.call(['ls', '-las'] + $words[2])  $str  \n";
	}
	#sys.stdin.readline().rstrip()
	if($builtin_type == 4) {
		@words = split(/ /, $line[0]);
		print  "$words[1] = sys.stdin.readline().rstrip()  $str  \n";
	}
	#sys.exit(0|1) 
	if($builtin_type == 3) {
		@words = split(/ /, $line[0]);
		print  "sys.exit($words[1])  $str  \n";
	}
	#os.chdir('dir')
	if($builtin_type == 2) {
		@words = split(/ /, $line[0]);
		print  "os.chdir('$words[1]')  $str  \n";
	}
	#subprocess.call(['cmd'])
	if($builtin_type == 1) {
		@words = split(/ /, $line[0]);
		foreach $word (@words) {
			if($word =~ /\"\$@\"/) {
				$word = "sys.argv[1:]";
			}
			if($word =~ /\"\$[0-9]+\"/) {
				$word =~ s/[\$\"]//gi;
				$temp = "sys.argv[1]";
				$temp =~ s/1/$word/gi;
				$word = $temp;
			}
		}
		print  "subprocess.call([";
		for($i = 0;$i <= $#words;$i++) {
			if($i < $#words) {
				print  "'", "$words[$i]", "', ";
			}
			if($i == $#words) {
				print  "'", "$words[$i]", "'])  $str  \n";
			}
		}
	}	
}

# translate if statement
sub if_if {
	$t = $tab;
	while($t > 0) {
		print  "\t";
		$t--;
	}
	@line = @_;
	chomp @line;
	$line[0] =~ s/ \]//g;
	$line[0] =~ s/['\`]//g;

	# store comments
	$str = "";
	@coms = split(/ /, $line[0]);
	if($line[0] =~ /[ \t]+#.*/) {
		$line[0] =~ s/[ \t]+#.*//g;
		$flag = 0;
		$str = "";
		foreach $com (@coms) {
			if($com =~ /^[\t]*#.*$/) {
				$flag = 1;
				$temp = " ";
				$str = $str.$com;
				$str = $str.$temp;
				next;
			}
			if($flag == 1) {
				$temp = " ";
				$str = $str.$com;
				$str = $str.$temp;
				next;
			}
		}
	}

	@words = split(/ /, $line[0]);
	
	#if test sth
	if($if_type == 1) { 
		foreach $word (@words) {
			if($word =~ /^if$/) {
				print  "if ";
				next;
			}
			elsif($word =~ /^elif$/) {
				print  "elif ";
				next;
			}
			elsif($word =~ /^test$/ or $word =~ /^\[$/ or $word =~ /^expr$/) {
				next;
			}
			elsif($word =~ /^[a-z]+$/i) {
				print  "'$word' ";
			}
			elsif($word =~ /^\-a$/) {
				print  "and ";
			}
			elsif($word =~ /^\-o$/) {
				print  "or ";
			}
			elsif($word =~ /^\$\#$/) {
				print  "int(len(sys.argv[1:])) ";
			}
			elsif($word =~ /^\$\@$/ or $word =~ /^\$\*$/) {
				print  "\"sys.argv[1:]\" ";
			}
			elsif($word =~ /\$[1-9]+/i) {
				$word =~ s/\$//g;
				$temp = "sys.argv[1]";
				$temp =~ s/1/$word/gi;
				print  "\"$temp\" ";
			}
			elsif($word =~ /\$[a-z].*/i) {
				$word =~ s/\$//gi;
				print  "int($word) ";
			}
			elsif($word =~ /^=$/) {
				print  "== ";
			}
			elsif($word =~ /^\!=$/) {
				print  "!= ";
			}
			elsif($word =~ /^\-lt$/) {
				print  "< ";
			}
			elsif($word =~ /^\-le$/) {
				print  "<= ";
			}
			elsif($word =~ /^\-eq$/) {
				print  "== ";
			}
			elsif($word =~ /^\-ne$/) {
				print  "!= ";
			}
			elsif($word =~ /^\-ge$/) {
				print  ">= ";
			}
			elsif($word =~ /^\-gt$/) {
				print  "> ";
			}
			elsif($word =~ /^\+$/) {
				print  "+ ";
			}
			elsif($word =~ /^\-$/) {
				print  "- ";
			}
			elsif($word =~ /^\*$/) {
				print  "* ";
			}
			elsif($word =~ /^\/$/) {
				print  "/ ";
			}
			elsif($word =~ /^\%$/) {
				print  "% ";
			}
			else {
				print  "$word ";
			}
		}
		print  ":  $str \n";
	}
	#if test -r
	if($if_type == 2) {
		if($words[0] =~ /^if$/i) {
			print  "if os.access('$words[3]', os.R_OK):  $str \n";
		}
		else {
			print  "elif os.access('$words[3]', os.R_OK):  $str \n";
		}
	}
	#if test -d
	if($if_type == 3) {
		if($words[0] =~ /^if$/i) {
			print  "if os.path.isdir('$words[3]'):  $str \n";
		}
		else {
			print  "elif os.path.isdir('$words[3]'):  $str \n";
		}
	}
}

# translate while loop
sub while_loop {
	$t = $tab;
	while($t > 0) {
		print  "\t";
		$t--;
	}
	@line = @_;
	chomp @line;

	# store comments
	$str = "";
	@coms = split(/ /, $line[0]);
	if($line[0] =~ /[ \t]+#.*/) {
		$line[0] =~ s/[ \t]+#.*//g;
		$flag = 0;
		$str = "";
		foreach $com (@coms) {
			if($com =~ /^[\t]*#.*$/) {
				$flag = 1;
				$temp = " ";
				$str = $str.$com;
				$str = $str.$temp;
				next;
			}
			if($flag == 1) {
				$temp = " ";
				$str = $str.$com;
				$str = $str.$temp;
				next;
			}
		}
	}

	@words = split(/ /, $line[0]);
	foreach $word (@words) {
		$word =~ s/[\[\]]//gi;
	} 
	if($while_type == 2) {
		print  "while True:  $str \n";
	}
	if($while_type == 1) {
		print  "while ";
		for($i = 2;$i <= $#words;$i++) {
			$words[$i] =~ s/['\`]//g;
			if($words[$i] =~ /\$[a-z]+/i) {
				$words[$i] =~ s/\$//gi;
				$temp = "int(1)";
				$temp =~ s/1/$words[$i]/gi;
				$words[$i] = $temp;
			}
			if($words[$i] =~ /^expr$/) {
				next;
			}
			if($words[$i] =~ /^\-a$/) {
				$words[$i] = "and";
			}
			if($words[$i] =~ /^\-o$/) {
				$words[$i] = "or";
			}
			if($words[$i] =~ /^\-le$/i) {
				$words[$i] = "<=";
			}
			if($words[$i] =~ /^\-lt$/i) {
				$words[$i] = "<";
			}
			if($words[$i] =~ /^\-eq$/i) {
				$words[$i] = "==";
			}
			if($words[$i] =~ /^\-ne$/i) {
				$words[$i] = "!=";
			}
			if($words[$i] =~ /^\-gt$/i) {
				$words[$i] = ">";
			}
			if($words[$i] =~ /^\-ge$/i) {
				$words[$i] = ">=";
			}
			if($i < $#words) {
				print  "$words[$i] ";
			}
			if($i == $#words) {
				print  "$words[$i]:  $str \n";
			}
		}
	}
}

# translate for loop
sub for_loop {
	$t = $tab;
	while($t > 0) {
		print  "\t";
		$t--;
	}
	@line = @_;
	chomp @line;

	# store comments
	$str = "";
	@coms = split(/ /, $line[0]);
	if($line[0] =~ /[ \t]+#.*/) {
		$line[0] =~ s/[ \t]+#.*//g;
		$flag = 0;
		$str = "";
		foreach $com (@coms) {
			if($com =~ /^[\t]*#.*$/) {
				$flag = 1;
				$temp = " ";
				$str = $str.$com;
				$str = $str.$temp;
				next;
			}
			if($flag == 1) {
				$temp = " ";
				$str = $str.$com;
				$str = $str.$temp;
				next;
			}
		}
	}

	@words = split(/ /, $line[0]);
	print  "for $words[1] in ";
	for($i = 3;$i <= $#words;$i++) {
		if($words[$i] =~ /\$@/ or $words[$i] =~ /\$\*/) {
			print  "sys.argv[1:]:  $str \n";
		}
		else {
			if($i < $#words) {
				print  "'$words[$i]', ";
			}
			if($i == $#words) {
				print  "'$words[$i]':  $str \n";
			}
		}
	}
}

# translate equation
sub equation {
	$t = $tab;
	while($t > 0) {
		print  "\t";
		$t--;
	}
	@line = @_;
	chomp @line;

	# store comments
	$str = "";
	@coms = split(/ /, $line[0]);
	if($line[0] =~ /[ \t]+#.*/) {
		$line[0] =~ s/[ \t]+#.*//g;
		$flag = 0;
		$str = "";
		foreach $com (@coms) {
			if($com =~ /^[\t]*#.*$/) {
				$flag = 1;
				$temp = " ";
				$str = $str.$com;
				$str = $str.$temp;
				next;
			}
			if($flag == 1) {
				$temp = " ";
				$str = $str.$com;
				$str = $str.$temp;
				next;
			}
		}
	}

	@words = split(/\=/, $line[0]);
	$words[0] =~ s/\$//gi;

	# format is number=`expr $number + 1`
	if($eq_type == 1) {
		print  "$words[0] = ";
		@ones = split(/ /, $words[1]);
		foreach $one (@ones) {
			$one =~ s/['\`]//gi;
			if($one =~ /^expr$/) {
				next;
			}
			if($one =~ /\$[a-z].*/i) {
				$one =~ s/\$//g;
				$temp = "int(1)";
				$temp =~ s/1/$one/g;
				$one = $temp
			}
			if($one =~ /\$[1-9]+/) {
				$one =~ s/\$//g;
				$temp = "int(sys.argv[1])";
				$temp =~ s/1/$one/g;
				$one = $temp
			}
			print  "$one ";
		}
		print  " $str \n";
	}

	# format is number=$(($number + 1))
	if($eq_type == 2) {
		print  "$words[0] = ";
		@ones = split(/ /, $words[1]);
		$ones[0] =~ s/\$\(\(//g;
		foreach $one (@ones) {
			$one =~ s/\)//g;
			if($one =~ /\$[a-z][a-z0-9_]*/i) {
					$one =~ s/\$//g;
					$temp = "int(1)";
					$temp =~ s/1/$one/g;
					$one = $temp;
			}
			if($one =~ /\$[1-9]+/i) {
					$one =~ s/\$//g;
					$temp = "int(sys.argv[1])";
					$temp =~ s/1/$one/g;
					$one = $temp;
			} 
			print  "$one ";
		}
		print  " $str \n";
	}

	# format is number=a+c or number=$1+$c...
	if($eq_type == 3) {
		print  "$words[0] = ";
		@chars = split(//, $words[1]);
		$flag = 0;
		foreach $char (@chars) {
			if($char =~ /\$/) {
				$flag = 1;
				next;
			}
			if($char =~ /['"]/) {
				next;
			}
			#if($char =~ /\+/) {
			#	print  "'+' +";
			#}
			if($flag == 1 and $char =~ /[a-z]/i) {
				print  "$char + ";
				$flag = 0;
				next;
			}
			if($flag == 1 and $char =~ /[1-9]/) {
				$temp = "sys.argv[1]";
				$temp =~ s/1/$char/g;
				print  "$temp + ";
				$flag = 0;
				next;
			}
			else {
				print  "'$char' + ";
				next;
			}
		}
		print  "''  $str \n"; 
	}	

	# format is a=hello
	if($eq_type == 4) {
		print  "$words[0] = '$words[1]'  $str \n";
	}

	#format is a=$1
	if($eq_type == 5) {
		$words[1] =~ s/\$//;
		print  "$words[0] = sys.argv[$words[1]]  $str \n";
	}

	#format is a=$start
	if($eq_type == 6) {
		$words[1] =~ s/\$//;
		print  "$words[0] = $words[1]  $str \n";
	}

	#format is a=1
	if($eq_type == 7) {
		print  "$words[0] = $words[1]  $str \n";
	}

	#format is a='abc'
	if($eq_type == 8) {
		print  "$words[0] = $words[1]  $str \n";
	}

	#format is a="abc" or a="hello $name"
	if($eq_type == 9) {
		if($words[1] =~ /\$/) {
			$words[1] =~ s/\"//g;
			print  "$words[0] = ";
			@ones = split(/ /, $words[1]);
			for($i = 0;$i <= $#ones;$i++) {
				if($ones[$i] =~ /\$/) {
					$ones[$i] =~ s/\"//g;
					if($ones[$i] =~ /\$[1-9]+/) {
						$ones[$i] =~ s/\$//g;
						$temp = "sys.argv[1]";
						$temp =~ s/1/$ones[$i]/g;
						$ones[$i] = $temp;
					}
					if($ones[$i] =~ /\$[a-z][a-z0-9_]*/i) {
						$ones[$i] =~ s/\$//g;
					}
					if($ones[$i] =~ /\$\#/) {
						$ones = "len(sys.argv[1:])";
					}
					if($i < $#ones) {
						print  "$ones[$i] + ' ' + ";
					}
					if($i == $#ones) {
						print  "$ones[$i]\n";
					}
				}
				else {
					if($i < $#ones) {
						print  "\"$ones[$i] \" + ";
					}
					if($i == $#ones) {
						print  "\"$ones[$i] \"  $str \n";
					}
				}
			}

		}
		else {
			print  "$words[0] = $words[1]  $str \n";
		}
	}
}

# translate echo
sub echo_print {
	$t = $tab;
	while($t > 0) {
		print  "\t";
		$t--;
	}
	@line = @_;
	chomp @line;

	# store comments
	$str = "";
	@coms = split(/ /, $line[0]);
	if($line[0] =~ /[ \t]+#.*/) {
		$line[0] =~ s/[ \t]+#.*//g;
		$flag = 0;
		$str = "";
		foreach $com (@coms) {
			if($com =~ /^[\t]*#.*$/) {
				$flag = 1;
				$temp = " ";
				$str = $str.$com;
				$str = $str.$temp;
				next;
			}
			if($flag == 1) {
				$temp = " ";
				$str = $str.$com;
				$str = $str.$temp;
				next;
			}
		}
	}

	if($line[0] =~ /echo \-n/i) {
		$dashn = 1;
		$line[0] =~ s/\-n//gi;
	}
	if($line[0] =~ /\$/) {
		$var = 1;
	}
	#echo type is cmd in backquotes
	if($echo_type == 6) {
		@words = split(/\`/, $line[0]);
		$temp = "subprocess.call(['1'])";
		$temp =~ s/1/$words[1]/g;
		print  "$temp,\n";
	}
	#echo type is expr in backquotes
	elsif($echo_type == 5) {
		$line[0] =~ s/'//g;
		@words = split(/\`/, $line[0]);
		print  "print ";
		$words[1] =~ s/\`//g;
		@ones = split(/ /, $words[1]);
		foreach $one (@ones) {
			if($one =~ /^expr$/) {
				next;
			}
			elsif($one =~ /\$[1-9]+/) {
				$one =~ s/\$//g;
				$temp = "int(sys.argv[1])";
				$temp =~ s/1/$one/g;
				$one = $temp;
				print  "$one ";
			}
			elsif($one =~ /\$[a-z].*/i) {
				$one =~ s/\$//g;
				print  "$one ";
			}
			elsif($one =~ /\$\#/) {
				$one = "len(sys.argv[1:])";
				print  "$one ";
			}
			elsif($one =~ /\$\@/ or $one =~ /\$\*/) {
				$one = "sys.argv[1:]";
				print  "$one ";
			}
			else {
				print  "$one ";
			}
		}
		if($dashn == 0) {
			print  "  $str \n";
		}
		if($dashn == 1) {
			print  ",  $str \n";
		}
	}
	#echo type mixed with single quotes and double quotes
	elsif($echo_type == 4) {
		@words = split(/ /, $line[0]);
		print  "print ";
		for($i = 1;$i <= $#words;$i++) {
			if($i < $#words) {
				if($words[$i] =~ /^'.*/ or $words[$i] =~ /.*'$/) {
					$words[$i] =~ s/'//g;
					print  "'$words[$i] ' + ";
				}
				elsif($words[$i] =~ /^".*/ or $words[$i] =~ /.*"$/) {
					$words[$i] =~ s/"//g;
					if($words[$i] =~ /\$[1-9]+/) {
						$words[$i] =~ s/\$//g;
						$temp = "sys.argv[1]";
						$temp =~ s/1/$words[$i]/g;
						$words[$i] = $temp;
						print  "$words[$i] + ' ' + ";
						next;
					}
					elsif($words[$i] =~ /\$[a-z][a-z0-9_]*/i) {
						$words[$i] =~ s/\$//g;
						print  "$words[$i] + ' ' + ";
						next;
					}
					elsif($words[$i] =~ /\$\#/) {
						$words[$i] = "len(sys.argv[1:])";
						print  "$words[$i] + ' ' + ";
						next;
					}
					elsif($words[$i] =~ /\$\@/ or $words[$i] =~ /\$\*/) {
						$words[$i] = "sys.argv[1:]";
						print  "$words[$i] + ' ' + ";
						next;
					}
					else {
						print  "\"$words[$i] \" + ";
					}
				}
				else {
					if($words[$i] =~ /\$[1-9]+/) {
						$words[$i] =~ s/\$//g;
						$temp = "sys.argv[1]";
						$temp =~ s/1/$words[$i]/g;
						$words[$i] = $temp;
						print  "$words[$i] + ' ' + ";
						next;
					}
					elsif($words[$i] =~ /\$[a-z][a-z0-9_]*/i) {
						$words[$i] =~ s/\$//g;
						print  "$words[$i] + ' ' + ";
						next;
					}
					elsif($words[$i] =~ /\$\#/) {
						$words[$i] = "len(sys.argv[1:])";
						print  "$words[$i] + ' ' + ";
						next;
					}
					elsif($words[$i] =~ /\$\@/ or $words[$i] =~ /\$\*/) {
						$words[$i] = "sys.argv[1:]";
						print  "$words[$i] + ' ' + ";
						next;
					}
					else {
						print  "'$words[$i] ' + ";
					}
				}
			}
			if($i == $#words) {
				if($dashn == 0) {
					if($words[$i] =~ /^'.*/ or $words[$i] =~ /.*'$/) {
						$words[$i] =~ s/'//g;
						print  "'$words[$i]'  $str \n";
					}
					elsif($words[$i] =~ /^".*/ or $words[$i] =~ /.*"$/) {
						$words[$i] =~ s/"//g;
						if($words[$i] =~ /\$[1-9]+/) {
							$words[$i] =~ s/\$//g;
							$temp = "sys.argv[1]";
							$temp =~ s/1/$words[$i]/g;
							$words[$i] = $temp;
							print  "$words[$i]  $str \n";
						}
						elsif($words[$i] =~ /\$[a-z][a-z0-9_]*/i) {
							$words[$i] =~ s/\$//g;
							print  "$words[$i]\n";
						}
						elsif($words[$i] =~ /\$\#/) {
							$words[$i] = "len(sys.argv[1:])";
							print  "$words[$i]  $str \n";
						}
						elsif($words[$i] =~ /\$\@/ or $words[$i] =~ /\$\*/) {
							$words[$i] = "sys.argv[1:]";
							print  "$words[$i]  $str \n";
						}
						else {
							print  "\"$words[$i]\"  $str \n";
						}
					}
					else {
						if($words[$i] =~ /\$[1-9]+/) {
							$words[$i] =~ s/\$//g;
							$temp = "sys.argv[1]";
							$temp =~ s/1/$words[$i]/g;
							$words[$i] = $temp;
							print  "$words[$i]  $str \n";
						}
						elsif($words[$i] =~ /\$[a-z][a-z0-9_]*/i) {
							$words[$i] =~ s/\$//g;
							print  "$words[$i]  $str \n";
						}
						elsif($words[$i] =~ /\$\#/) {
							$words[$i] = "len(sys.argv[1:])";
							print  "$words[$i]  $str \n";
						}
						elsif($words[$i] =~ /\$\@/ or $words[$i] =~ /\$\*/) {
							$words[$i] = "sys.argv[1:]";
							print  "$words[$i]  $str \n";
						}
						else {
							print  "'$words[$i]'  $str \n";
						}
					}
				}
				if($dashn == 1) {
					if($words[$i] =~ /^'.*/ or $words[$i] =~ /.*'$/) {
						$words =~ s/'//g;
						print  "'$words[$i]',  $str \n";
					}
					elsif($words[$i] =~ /^".*/ or $words[$i] =~ /.*"$/) {
						$words[$i] =~ s/"//g;
						if($words[$i] =~ /\$[1-9]+/) {
							$words[$i] =~ s/\$//g;
							$temp = "sys.argv[1]";
							$temp =~ s/1/$words[$i]/g;
							$words[$i] = $temp;
							print  "$words[$i],  $str \n";
						}
						elsif($words[$i] =~ /\$[a-z][a-z0-9_]*/i) {
							$words[$i] =~ s/\$//g;
							print  "$words[$i],  $str \n";
						}
						elsif($words[$i] =~ /\$\#/) {
							$words[$i] = "len(sys.argv[1:])";
							print  "$words[$i],  $str \n";
						}
						elsif($words[$i] =~ /\$\@/ or $words[$i] =~ /\$\*/) {
							$words[$i] = "sys.argv[1:]";
							print  "$words[$i],  $str \n";
						}
						else {
							print  "\"$words[$i]\",  $str \n";
						}
					}
					else {
						if($words[$i] =~ /\$[1-9]+/) {
							$words[$i] =~ s/\$//g;
							$temp = "sys.argv[1]";
							$temp =~ s/1/$words[$i]/g;
							$words[$i] = $temp;
							print  "$words[$i],  $str \n";
						}
						elsif($words[$i] =~ /\$[a-z][a-z0-9_]*/i) {
							$words[$i] =~ s/\$//g;
							print  "$words[$i],  $str \n";
						}
						elsif($words[$i] =~ /\$\#/) {
							$words[$i] = "len(sys.argv[1:])";
							print  "$words[$i],  $str \n";
						}
						elsif($words[$i] =~ /\$\@/ or $words[$i] =~ /\$\*/) {
							$words[$i] = "sys.argv[1:]";
							print  "$words[$i],  $str \n";
						}
						else {
							print  "'$words[$i]',  $str \n";
						}
					}
				}
			}
		}
	}
	# echo type is double quotes only
	elsif($echo_type == 3) {
		@words = split(/ /, $line[0]);
		if($var == 0) {
			print  "print ";
			for($i = 1;$i <= $#words;$i++) {
				$words[$i] =~ s/"//g;
				if($i < $#words) {
					print  "\"$words[$i] \" + ";
				}
				if($i == $#words and $dashn == 0) {
					print  "\"$words[$i]\"  $str \n";
				}
				if($i == $#words and $dashn == 1) {
					print  "\"$words[$i]\",  $str \n";
				}
			}
		}
		if($var == 1) {
			print  "print ";
			for($i = 1;$i <= $#words;$i++) {
				$words[$i] =~ s/"//g;		
				if($words[$i] =~ /\$[1-9]+/) {
					$words[$i] =~ s/\$//g;
					$temp = "sys.argv[1]";
					$temp =~ s/1/$words[$i]/g;
					$words[$i] = $temp;
					if($i < $#words) {
						print  "$words[$i] + \" \" + ";
						next;
					}
					if($i == $#words) {
						if($dashn == 0) {
							print  "$words[$i]  $str \n";
						}
						if($dashn == 1) {
							print  "$words[$i],  $str \n";
						}
					}
				}
				elsif($words[$i] =~ /\$[a-z][a-z0-9_]*/i) {
					$words[$i] =~ s/\$//g;
					if($i < $#words) {
						print  "$words[$i] + \" \" + ";
						next;
					}
					if($i == $#words) {
						if($dashn == 0) {
							print  "$words[$i]  $str \n";
						}
						if($dashn == 1) {
							print  "$words[$i],  $str \n";
						}
					}
				}
				elsif($words[$i] =~ /\$\#/) {
					$words[$i] = "len(sys.argv[1:])";
					if($i < $#words) {
						print  "$words[$i] + \" \" + ";
						next;
					}
					if($i == $#words) {
						if($dashn == 0) {
							print  "$words[$i]  $str \n";
						}
						if($dashn == 1) {
							print  "$words[$i],  $str \n";
						}
					}
				}
				elsif($words[$i] =~ /\$\@/ or $words[$i] =~ /\$\*/) {
					$words[$i] = "sys.argv[1:]";
					if($i < $#words) {
						print  "$words[$i] + \" \" + ";
						next;
					}
					if($i == $#words) {
						if($dashn == 0) {
							print  "$words[$i]  $str \n";
						}
						if($dashn == 1) {
							print  "$words[$i],  $str \n";
						}
					}
				}
				else {
					if($i < $#words) {
						print  "\"$words[$i] \" + ";
					}
					if($i == $#words) {
						if($dashn == 0) {
							print  "\"$words[$i]\"  $str \n";
						}
						if($dashn == 1) {
							print  "\"$words[$i]\",  $str \n";
						}
					}
				}
			}
		}
	}

	#echo type is single quotes
	elsif($echo_type == 2) {
		if($var == 0) {
			@words = split(/ /, $line[0]);
			print  "print ";
			for($i = 1;$i <= $#words;$i++) {
				$words[$i] =~ s/'//g;
				if($i < $#words) {
					print  "'$words[$i] ' + ";
				}
				if($i == $#words) {
					if($dashn == 0) {
						print  "'$words[$i]'  $str \n";
					}
					if($dashn == 1) {
						print  "'$words[$i]',  $str \n";
					}
				}
			}
		}
		if($var == 1) {
			@words = split(/ /, $line[0]);
			print  "print ";
			for($i = 1;$i <= $#words;$i++) {
				if($words[$i] =~ /'.*'/) {
					$words[$i] =~ s/'//g;
					if($i < $#words) {
						print  "'$words[$i] ' + ";
					}
					if($i == $#words) {
						if($dashn == 0) {
							print  "'$words[$i]'  $str \n";
						}
						if($dashn == 1) {
							print  "'$words[$i]',  $str \n";
						}
					}
				}
				else {
					if($words[$i] =~ /\$[1-9]+/) {
						$words[$i] =~ s/\$//g;
					$	temp = "sys.argv[1]";
						$temp =~ s/1/$words[$i]/g;
						$words[$i] = $temp;
						if($i < $#words) {
							print  "$words[$i] + \' \' + ";
							next;
						}
						if($i == $#words) {
							if($dashn == 0) {
								print  "$words[$i]  $str \n";
							}
							if($dashn == 1) {
								print  "$words[$i],  $str \n";
							}
						}
					}
					elsif($words[$i] =~ /\$[a-z].*/i) {
						$words[$i] =~ s/\$//g;
						if($i < $#words) {
							print  "$words[$i] + \' \' + ";
							next;
						}
						if($i == $#words) {
							if($dashn == 0) {
								print  "$words[$i]  $str \n";
							}
							if($dashn == 1) {
								print  "$words[$i], $str \n";
							}
						}
					}
					elsif($words[$i] =~ /\$\#/) {
						$words[$i] = "len(sys.argv[1:])";
					if($i < $#words) {
						print  "$words[$i] + \' \' + ";
						next;
					}
					if($i == $#words) {
						if($dashn == 0) {
							print  "$words[$i]  $str \n";
						}
						if($dashn == 1) {
							print  "$words[$i],  $str \n";
						}
					}
					}
					elsif($words[$i] =~ /\$\@/ or $words[$i] =~ /\$\*/) {
						$words[$i] = "sys.argv[1:]";
						if($i < $#words) {
							print  "$words[$i] + \' \' + ";
							next;
						}
						if($i == $#words) {
							if($dashn == 0) {
								print  "$words[$i]  $str \n";
							}
							if($dashn == 1) {
								print  "$words[$i],  $str \n";
							}
						}
					}
					else {
						if($i < $#words) {
							print  "'$words[$i] ' + ";
						}
						if($i == $#words) {
							if($dashn == 0) {
								print  "'$words[$i]'  $str \n";
							}
							if($dashn == 1) {
								print  "'$words[$i]',  $str \n"
							}
						}
					}
				}
			}
		}
	}

	#echo type is no quotes
	elsif($echo_type == 1) {
		print  "print ";
		@words = split(/ /, $line[0]);
		if($var == 0) {
			for($i = 1;$i <= $#words;$i++) {
				if($i < $#words) {
					print  "'$words[$i]', ";
				}
				if($i == $#words) {
					if($dashn == 0) {
						print  "'$words[$i]'  $str \n";
					}
					if($dashn == 1) {
						print  "'$words[$i]',  $str \n";
					}
				}
			}
		}
		if($var == 1) {
			for($i = 1;$i <= $#words;$i++) {
				if($i < $#words) {
					if($words[$i] =~ /\$[a-z][a-z0-9_]*/) {
						$words[$i] =~ s/\$//g;
						print  "$words[$i] + \' \' + ";
						next;		
					}
					if($words[$i] =~ /\$[1-9]+/) {
						$words[$i] =~ s/\$//g;
						$temp = "sys.argv[1]";
						$temp =~ s/1/$words[$i]/g;
						$words[$i] = $temp;
						print  "$words[$i] + \' \' + ";
						next;		
					}
					else {
						print  "\'$words[$i] \' + ";
					}
				}
				if($i == $#words) {
					if($dashn == 0) {
						if($words[$i] =~ /\$[a-z][a-z0-9_]*/) {
							$words[$i] =~ s/\$//g;
							print  "$words[$i]  $str \n";
							last;
						}
						if($words[$i] =~ /\$[1-9]+/) {
							$words[$i] =~ s/\$//g;
							$temp = "sys.argv[1]";
							$temp =~ s/1/$words[$i]/g;
							$words[$i] = $temp;
							print  "$words[$i]  $str \n";
							last;		
						}
						else {
							print  "\'$words[$i]\'  $str \n";
						}
					}
					if($dashn == 1) {
						if($words[$i] =~ /\$[a-z][a-z0-9_]*/) {
							$words[$i] =~ s/\$//g;
							print  "$words[$i],  $str \n";
						}
						if($words[$i] =~ /\$[1-9]+/) {
							$words[$i] =~ s/\$//g;
							$temp = "sys.argv[1]";
							$temp =~ s/1/$words[$i]/g;
							$words[$i] = $temp;
							print  "$words[$i],  $str \n";		
						}
						else {
							print  "\'$words[$i]\',  $str \n";
						}
					}
				}
			}
		}
	}
}
