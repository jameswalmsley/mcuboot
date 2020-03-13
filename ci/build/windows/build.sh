#!/bin/bash

############################
# Windows specific definitions
MODUS_TOOLCHAIN_PATH="${MODUS_TOOLCHAIN_PATH:-C:\Users\fw-security\ModusToolbox\tools_2.0\gcc-7.2.1}"
MODUS_SHELL_BIN="C:\Users\fw-security\ModusToolbox\tools_2.0\modus-shell\bin"
PYTHON_DIR="${PYTHON_DIR:-C:\Python38}"

############################
# Setup environment variables 
#
function setup_environment {
    #export http_proxy=http://csj-mwg01.cysemi.com:8080
    #export https_proxy=$http_proxy

    LC_ALL=en_US
    export LC_ALL

    TOOLCHAIN_PATH=$(path_win_to_cygpath $MODUS_TOOLCHAIN_PATH)
}

############################
# Prepare to build
#
function prepare_to_build {    

    #virtualenv $(path_cygwin_to_win "$ROOT_DIR/venv")
    
    [[ -d ${ROOT_DIR}/venv ]] || cmd_check virtualenv  --python=python3.7 "$ROOT_DIR/venv" 
   
    source $ROOT_DIR/venv/bin/activate
    
    print "[DEBUG] Python path: $(which python)"

    #cmd <<< "pip install pyserial"
    
    [[ -d ${ROOT_DIR}/venv/lib/python3.7/site-packages/serial ]] || cmd_check pip install pyserial
    
    [[ -d ${ROOT_DIR}/venv/lib/python3.7/site-packages/cysecuretools ]] || cmd_check pip install git+http://git-ore.aus.cypress.com/repo/cysecuretools.git@$CY_SECURETOOLS_BRANCH
    #install_cy_pymodule "cysecuretools" "http://git-ore.aus.cypress.com/repo/cysecuretools.git" $CY_SECURETOOLS_BRANCH

    #cmd_check pip install --upgrade --force-reinstall git+http://git-ore.aus.cypress.com/repo/pyocd.git@ww05-sync-0.24.1
    #install_cy_pymodule "pyocd" "http://git-ore.aus.cypress.com/repo/pyocd.git" $PYOCD_BRANCH
    [[ -d ${ROOT_DIR}/venv/lib/python3.7/site-packages/pyocd ]] || cmd_check pip install git+http://git-ore.aus.cypress.com/repo/pyocd.git@$PYOCD_BRANCH
    
    local cy_secure_tools_path=$(python -c "import cysecuretools; import os; print(os.path.dirname(os.path.dirname(cysecuretools.__file__)))")
    echo "[INFO]: CY_SEC_TOOLS ${cy_secure_tools_path}"
    cmd_check cp -R ${ROOT_DIR}/../../../../keys ${cy_secure_tools_path}/cysecuretools/targets/cy8ckit_064x0s2_4343w/
    cmd_check cp -R ${ROOT_DIR}/../../../../keys ${cy_secure_tools_path}/cysecuretools/targets/cy8cproto_064s1_sb/
    cmd_check cp -R ${ROOT_DIR}/../../../../keys ${cy_secure_tools_path}/cysecuretools/targets/cy8cproto_064s2_sb/
    cmd_check cp -R ${ROOT_DIR}/../../../../keys ${cy_secure_tools_path}/cysecuretools/targets/cyb06xx5/
    cmd_check cp -R ${ROOT_DIR}/../../../../keys ${cy_secure_tools_path}/cysecuretools/targets/cyb06xx7/
    cmd_check cp -R ${ROOT_DIR}/../../../../keys ${cy_secure_tools_path}/cysecuretools/targets/cyb06xxa/
}

############################
# Install Cy Python module for repo
#
function install_cy_pymodule {
    local _name=$1
    local _url=$2
    local _branch=$3
    
    local _dir_loc="$ROOT_DIR/${_name}_loc"

    if [ ! -d "$_dir_loc" ]; then
        cmd_check git clone $_url $_dir_loc > /dev/null 2>&1
    fi
    
    pushd "$_dir_loc"
        cmd_check git checkout --force $_branch

    popd
}

############################
# Fetch inputs before build
#
function fetch_inputs {
    echo -e "\n[INFO] Fetching build inputs..."
}

############################
# Build 
#
function build {

    pushd "$BOOT_CY_DIR"
    
    CURDIR=$(pwd | cygpath -m -f -)
    #CURDIR=.
    #local cy_secure_tools_path=$(python -c "import cysecuretools; import os; print(os.path.dirname(os.path.dirname(cysecuretools.__file__)))")
    #export CY_SEC_TOOLS_PATH=$(path_win_backslash $cy_secure_tools_path )

    unset_build_app_vars
    
    possible_parameters=(APP_NAME APP_SUFX PLATFORM IMG_TYPE MULTI_IMAGE MAKEINFO BUILDCFG CURDIR TOOLCHAIN_PATH POST_BUILD TARGET)
    
   
    for input_param in "$@"
    do
        IFS='=' read -ra param_value <<< "$input_param"
        for param_name in ${possible_parameters[*]}
        do
            if [[ ${param_value[0]} == ${param_name} ]]
            then
                printf -v ${param_name} "${param_value[1]}" 
            fi
        done      
    done

    build_app

    popd
}


############################
# Collect build outputs
#
function collect_outputs {
    echo "[INFO] Aggregating build aritfacts..."

    collect_common
}

