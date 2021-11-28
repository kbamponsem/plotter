#!/bin/bash

__check_for_jq(){
    if [[ "$(which jq)" == "" ]];
    then
        echo "Please install jq!"
        return 1
    else
        return 0
    fi
}

__execute_plotter () {
    local INPUT_FILE=`realpath $1`
    local OUTPUT_FILE=`realpath $2`
    local TITLE=$3
    local X_LABEL=$4
    local Y_LABEL=$5
    local PLOTTER=`realpath $6`

    echo -e "Plotting $INPUT_FILE into $OUTPUT_FILE with title: $TITLE, xlabel: $X_LABEL, ylabel: $Y_LABEL using $PLOTTER"

    gnuplot -e "input_file='$INPUT_FILE'; output_file='$OUTPUT_FILE'; title='$TITLE'; x_label='$X_LABEL'; y_label='$Y_LABEL'" $PLOTTER

}

plot(){
    __check_for_jq || return
    __setup_plotter $@
}

__setup_plotter()
{
    # Load Plotterfile
    file_switch=$(echo $@ | awk -F" " '{print $1}')
    plotter_file=$(echo $@ | awk -F" " '{print $2}')

    if [[ "$plotter_file" == "" ]]; 
    then
        __help
        echo "Please provide a Plotterfile"

    elif [ -f "$plotter_file" ]; 
    then
        # Load the plotter file
        echo $plotter_file
        plotter_file=$(realpath $plotter_file)

        INPUT_FILE=$(cat $plotter_file | grep INPUT_FILE | awk -F= '{print $2}')
        OUTPUT_FILE=$(cat $plotter_file | grep OUTPUT_FILE | awk -F= '{print $2}')
        PLOTTER=$(cat $plotter_file | grep PLOTTER | awk -F= '{print $2}')
        TITLE=$(cat $plotter_file | grep TITLE | awk -F= '{print $2}')
        X_LABEL=$(cat $plotter_file | grep X_LABEL | awk -F= '{print $2}')
        Y_LABEL=$(cat $plotter_file | grep Y_LABEL | awk -F= '{print $2}')

        if [[ "$PLOTTER" != "" && "$INPUT_FILE" != "" && "$OUTPUT_FILE" != "" ]];
        then
            echo ""
            __execute_plotter "$INPUT_FILE" "$OUTPUT_FILE" "$TITLE" "$X_LABEL" "$Y_LABEL" "$PLOTTER"
        else
            echo "Please provide a PLOTTER in Plotterfile"
        fi
    else
        __help
    fi
}

createplotterfile(){

    __check_for_jq || return

    local dir_switch=$(echo $@ | awk -F" " '{print $1}')
    local dir=$(echo $@ | awk -F" " '{print $2}')

    local arr_data=$3
    local arr_length=$(echo $arr_data | jq length)    

    for i in `seq 0 $(perl -e "print $arr_length - 1")`;
    do
        case $i in 
            0)
                local input_file=$(echo $arr_data | jq .[$i] | sed 's/"//g')
            ;;
            1)
                local output_file=$(echo $arr_data | jq .[$i] | sed 's/"//g')
            ;;
            2)
                local plotter=$(echo $arr_data | jq .[$i] | sed 's/"//g')
            ;;
            3)
                local title=$(echo $arr_data | jq .[$i] | sed 's/"//g')
            ;;
            4)
                local x_label=$(echo $arr_data | jq .[$i] | sed 's/"//g')
            ;;
            5)
                local y_label=$(echo $arr_data | jq .[$i] | sed 's/"//g')
            ;;
        esac
    done


    local template="INPUT_FILE=$input_file\nOUTPUT_FILE=$output_file\nPLOTTER=$plotter\nTITLE=$title\nX_LABEL=$x_label\nY_LABEL=$y_label"
    
    echo -e $template

    if [[ "$dir" != "" ]]; then
        if [ ! -d "$dir" ];
        then
            # Create directory first
            mkdir $dir
        fi

        if [ -f "$dir/Plotterfile" ];
        then
            echo "Plotterfile already exists!"
            return;
        else
            # Create Template Plotterfile in the directory provided
            cd $dir
            touch Plotterfile

            echo -e $template >> Plotterfile

            cd -
        fi
    
    else
        __help
    fi

}

__help (){
    echo -e "source plotter.sh"
    echo -e "createplotfile -d [directory name]."
    echo -e "setup_plotter -f [Plotterfile]"
}
