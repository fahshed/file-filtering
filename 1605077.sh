#!/bin/bash

if [ $# -eq 0 ]; then
	echo "Please run the script as: bash $0 working_dirrectory(optional) input_file_name"
	exit
fi

if [ $# -eq 1 ] && [ -d "$1" ]; then
	echo "Please run the script as: bash $0 working_dirrectory(optional) input_file_name"
	exit
fi

if [ $# -eq 1 ]; then
	input_file="$1";
elif [ $# -eq 2 ]; then
	input_file="$2";
fi

if test ! -f "$input_file"; then
	echo "File name is not valid."
	exit
fi

root="$(realpath .)"
if [ $# -gt 1 ]; then
	working_dir="$(realpath $1)"
else
	working_dir=$root
fi


relative_root="${working_dir##*/}"
prefix_to_remove="${working_dir%%$relative_root*}"

rm -rf ../output_dir
mkdir ../output_dir
output_dir="$(realpath ../output_dir)"

rm -f ../Output.csv
touch ../Output.csv
csv_dir="$(realpath ../Output.csv)"
echo File Path, Line No., Line >> "$csv_dir"

cmd=$(head -n 1 "$input_file")
nol=$(head -n 2 "$input_file" | tail -n 1)
word_to_search=$(tail -n 1 "$input_file")
file_count=0


traverse_directories()
{
	cd "$1"

	for f in *
	do
		if [ -d "$f" ]; then
			traverse_directories "$f"

		elif [ -f "$f" ]; then

			if file "$f" | grep -q text ; then

				if [ $cmd = "begin" ]; then

					if head -n $nol "$f" | grep -qi "$word_to_search"; then
						fn="${f%.*}"
						ext="${f##$fn}"
						line_no=$(grep -ni "$word_to_search" "$f" | head -n 1 | cut -d ":" -f 1)
						line=$(grep -ni "$word_to_search" "$f" | head -n 1 | cut -d ":" -f 2)

						current_root="$(realpath .)"
						file_path="${current_root}/${fn}${ext}"

						relative_dir="${current_root##$prefix_to_remove}"
						new_file_name="${relative_dir//"/"/"."}.${fn}${line_no}${ext}"
						#echo "new name   : " $new_file_name

						cp $f "${output_dir}/${new_file_name}"

						file_count=$(($file_count + 1))

						echo $file_path, $line_no, \"$line\" >> "$csv_dir"
					fi
				elif [ $cmd = "end" ]; then

					if tail -n $nol "$f" | grep -qi "$word_to_search"; then
						fn="${f%.*}"
						ext="${f##$fn}"
						line_no=$(grep -ni "$word_to_search" "$f" | tail -n 1 | cut -d ":" -f 1)
						line=$(grep -ni "$word_to_search" "$f" | tail -n 1 | cut -d ":" -f 2)

						current_root="$(realpath .)"
						file_path="${current_root}/${fn}${ext}"

						relative_dir="${current_root##$prefix_to_remove}"
						new_file_name="${relative_dir//"/"/"."}.${fn}${line_no}${ext}"
						#echo "new name   : " $new_file_name

						cp $f "${output_dir}/${new_file_name}"

						file_count=$(($file_count + 1))

						echo $file_path, $line_no, \"$line\" >> "$csv_dir"
					fi
				fi
			fi
		fi
	done

	cd ../
}

traverse_directories "$working_dir"

echo $file_count "Files contain" $word_to_search
