clear all
cls

sysuse auto, clear
local depvar 	"price"
local indepvars "weight gear"
local absvars 	"turn trunk"


reghdfe `depvar' `indepvars', a(`absvars')

qui include "reghdfe.mata", adopath
mata:
    // 0) Optional declaration
    // class FixedEffects scalar HDFE

    // 1) Create the object
    HDFE = FixedEffects() // Note that you can replace "HDFE" with whatever name you choose

    // 2) Set up options as needed
    HDFE.absvars = "`absvars'"

    // 3) Initialize (validate options)
    HDFE.init()

    // 4) Partial out once the normal way...
    // !!! Notice that partial_out() updates the HDFE.solution structure so I am not sure what would happen if you never run it
    HDFE.partial_out("`depvar' `indepvars'")

    // Partial out later directly
    // !! Notice that you don't need to load the data again from Stata; you can just update with GMM
    y = st_data(HDFE.sample, "`depvar'")
    x = st_data(HDFE.sample, "`indepvars'")
    data = y, x


    fun_transform = &transform_sym_kaczmarz()
    fun_accel = &accelerate_cg()

    // !! If you don't update the stdevs, you will get a bunch of problems
    HDFE.solution.stdevs = standardize_data(data)
    map_solver(HDFE, data, 10, fun_accel, fun_transform)


    // 5) Solve OLS
    data = HDFE.solution.data
    k = cols(data)
    y = data[., 1]
    x = data[., 2::k]
    b = qrsolve(x, y)

    // Note: we standardized variables when partialling out; need to undo this
    HDFE.solution.stdevs
    stdev_y = HDFE.solution.stdevs[1]
    stdev_x = HDFE.solution.stdevs[2..k]
    b :/ stdev_x' * stdev_y
end

exit
