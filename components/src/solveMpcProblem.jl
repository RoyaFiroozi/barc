# Variable definitions
# mdl.z_Ol[i,j] = z_OpenLoop, open loop prediction of the state, i = state, j = step

# States in path following mode:
# i = 1 -> s
# i = 2 -> ey
# i = 3 -> epsi
# i = 4 -> v

# States in LMPC and system ID mode:
# i = 1 -> xDot
# i = 2 -> yDot
# i = 3 -> psiDot
# i = 4 -> ePsi
# i = 5 -> eY
# i = 6 -> s

function solveMpcProblem(mdl::MpcModel,mpcSol::MpcSol,mpcCoeff::MpcCoeff,mpcParams::MpcParams,trackCoeff::TrackCoeff,lapStatus::LapStatus,posInfo::PosInfo,modelParams::ModelParams,zCurr::Array{Float64},uPrev::Array{Float64})

    # Load Parameters
    sol_status::Symbol
    sol_u::Array{Float64,2}
    sol_z::Array{Float64,2}

    # Update current initial condition, curvature and System ID coefficients
    setvalue(mdl.z0,zCurr)
    setvalue(mdl.uPrev,uPrev)
    setvalue(mdl.c_Vx,mpcCoeff.c_Vx)            # System ID coefficients
    setvalue(mdl.c_Vy,mpcCoeff.c_Vy)
    setvalue(mdl.c_Psi,mpcCoeff.c_Psi)
    setvalue(mdl.coeff,trackCoeff.coeffCurvature)       # Track curvature
    setvalue(mdl.coeffTermCost,mpcCoeff.coeffCost)      # Terminal cost
    setvalue(mdl.coeffTermConst,mpcCoeff.coeffConst)    # Terminal constraints

    # Solve Problem and return solution
    sol_status  = solve(mdl.mdl)
    sol_u       = getvalue(mdl.u_Ol)
    sol_z       = getvalue(mdl.z_Ol)

    # export data
    mpcSol.a_x = sol_u[1,1]
    mpcSol.d_f = sol_u[1,2]
    mpcSol.u   = sol_u
    mpcSol.z   = sol_z
    mpcSol.solverStatus = sol_status
    mpcSol.cost = zeros(6)
    mpcSol.cost = [0,getvalue(mdl.costZTerm),getvalue(mdl.constZTerm),getvalue(mdl.derivCost),0,getvalue(mdl.laneCost)]
    #mpcSol.cost = [getvalue(mdl.costZ),0,0,getvalue(mdl.derivCost),0,0]

    # Print information
    # println("--------------- MPC START -----------------------------------------------")
    # println("z0             = $(zCurr')")
    # #println("z_Ol           = $(sol_z)")
    # #println("u_Ol           = $(sol_u)")
    # println("c_Vx           = $(mpcCoeff.c_Vx)")
    # println("c_Vy           = $(mpcCoeff.c_Vy)")
    # println("c_Psi          = $(getvalue(mdl.c_Psi))")
     println("ParInt         = $(getvalue(mdl.ParInt))")
    # #println("u_prev         = $(getvalue(mdl.uPrev))")
    println("Solved, status = $sol_status")
    # println("Predict. to s  = $(sol_z[end,6])")
    # println("costZ          = $(mpcSol.cost[1])")
    # println("termCost       = $(mpcSol.cost[2])")
    # println("termConst      = $(mpcSol.cost[3])")
    # println("derivCost      = $(mpcSol.cost[4])")
    # println("controlCost    = $(mpcSol.cost[5])")
    # println("laneCost       = $(mpcSol.cost[6])")
    # println("costZ: epsi    = $(norm(sol_z[:,4]))")
    # println("costZ: ey      = $(norm(sol_z[:,5]))")
    # println("costZ: v       = $(norm(sol_z[:,1]-0.8))")
    # println("--------------- MPC END ------------------------------------------------")
    nothing
end

function solveMpcProblem_pathFollow(mdl::MpcModel_pF,mpcSol::MpcSol,mpcParams_pF::MpcParams,trackCoeff::TrackCoeff,posInfo::PosInfo,
                                    modelParams::ModelParams,zCurr::Array{Float64},uPrev::Array{Float64},lapStatus::LapStatus)

    # Load Parameters
    coeffCurvature  = trackCoeff.coeffCurvature::Array{Float64,1}
    v_ref       = mpcParams_pF.vPathFollowing


    z_ref1 = cat(2,zeros(mpcParams_pF.N+1,3),v_ref*ones(mpcParams_pF.N+1,1))
    z_ref2 = cat(2,zeros(mpcParams_pF.N+1,1),0.2*ones(mpcParams_pF.N+1,1),zeros(mpcParams_pF.N+1,1),v_ref*ones(mpcParams_pF.N+1,1))
    z_ref3 = cat(2,zeros(mpcParams_pF.N+1,1),-0.1*ones(mpcParams_pF.N+1,1),zeros(mpcParams_pF.N+1,1),v_ref*ones(mpcParams_pF.N+1,1))

    sol_status::Symbol
    sol_u::Array{Float64,2}
    sol_z::Array{Float64,2}

    # Update current initial condition, curvature and previous input
    setvalue(mdl.z0,zCurr)
    setvalue(mdl.uPrev,uPrev)
    setvalue(mdl.coeff,coeffCurvature)
    if lapStatus.currentLap == 1
        setvalue(mdl.z_Ref,z_ref1)
    elseif lapStatus.currentLap == 2
        setvalue(mdl.z_Ref,z_ref1)
    elseif lapStatus.currentLap == 3
        setvalue(mdl.z_Ref,z_ref1)
    end

    # Solve Problem and return solution
    sol_status  = solve(mdl.mdl)
    sol_u       = getvalue(mdl.u_Ol)
    sol_z       = getvalue(mdl.z_Ol)

    mpcSol.a_x = sol_u[1,1]
    mpcSol.d_f = sol_u[1,2]
    mpcSol.u   = sol_u
    mpcSol.z   = sol_z
    mpcSol.solverStatus = sol_status
    mpcSol.cost = zeros(6)
    #mpcSol.cost = [getvalue(mdl.costZ),0,0,getvalue(mdl.derivCost),getvalue(mdl.controlCost),0]

    # Print information
    # println("--------------- MPC PF START -----------------------------------------------")
    # println("z0             = $(zCurr')")
    println("Solved, status = $sol_status")
    # println("Predict. to s  = $(sol_z[end,1])")
    # #println("uPrev          = $(uPrev)")
    # println("--------------- MPC PF END ------------------------------------------------")
    nothing
end

function solveMpcProblem_convhull(m::MpcModel_convhull,mpcSol::MpcSol,mpcCoeff::MpcCoeff,mpcParams::MpcParams,trackCoeff::TrackCoeff,lapStatus::LapStatus,
                                  posInfo::PosInfo,modelParams::ModelParams,zCurr::Array{Float64},uPrev::Array{Float64},selectedStates::SelectedStates)

 # Load Parameters
    sol_status::Symbol
    sol_u::Array{Float64,2}
    sol_z::Array{Float64,2}

    selStates       = selectedStates.selStates::Array{Float64,2}
    statesCost      = selectedStates.statesCost::Array{Float64,1}

    # Update current initial condition, curvature and System ID coefficients
    setvalue(m.z0,zCurr)
    setvalue(m.uPrev,uPrev)
    setvalue(m.c_Vx,mpcCoeff.c_Vx)            # System ID coefficients
    setvalue(m.c_Vy,mpcCoeff.c_Vy)
    setvalue(m.c_Psi,mpcCoeff.c_Psi)
    setvalue(m.coeff,trackCoeff.coeffCurvature)       # Track curvature
    setvalue(m.selStates,selStates)
    setvalue(m.statesCost,statesCost)

     # Solve Problem and return solution
    sol_status  = solve(m.mdl)
    sol_u       = getvalue(m.u_Ol)
    sol_z       = getvalue(m.z_Ol)

    # export data
    mpcSol.a_x = sol_u[1,1]
    mpcSol.d_f = sol_u[1,2]
    mpcSol.u   = sol_u
    mpcSol.z   = sol_z
    #mpcSol.eps_alpha = getvalue(m.eps_alpha)
    mpcSol.solverStatus = sol_status
    mpcSol.cost = zeros(6)
    mpcSol.cost = [0,getvalue(m.terminalCost),getvalue(m.controlCost),getvalue(m.derivCost),0,getvalue(m.laneCost)]

    mpcSol.costSlack = zeros(6)
    mpcSol.costSlack = [getvalue(m.slackVx),getvalue(m.slackVy),getvalue(m.slackPsidot),getvalue(m.slackEpsi),getvalue(m.slackEy),getvalue(m.slackS)]


    println("Solved, status = $sol_status")

    nothing
end

function solveMpcProblem_test(m::MpcModel_test,mpcSol::MpcSol,mpcCoeff::MpcCoeff,mpcParams::MpcParams,trackCoeff::TrackCoeff,lapStatus::LapStatus,
                                  posInfo::PosInfo,modelParams::ModelParams,zCurr::Array{Float64},uPrev::Array{Float64},selectedStates::SelectedStates)

 # Load Parameters
    sol_status::Symbol
    sol_u::Array{Float64,2}
    sol_z::Array{Float64,2}

    selStates       = selectedStates.selStates::Array{Float64,2}
    statesCost      = selectedStates.statesCost::Array{Float64,1}

    # Update current initial condition, curvature and System ID coefficients
    setvalue(m.z0,zCurr)
    setvalue(m.uPrev,uPrev)
    setvalue(m.c_Vx,mpcCoeff.c_Vx)            # System ID coefficients
    setvalue(m.c_Vy,mpcCoeff.c_Vy)
    setvalue(m.c_Psi,mpcCoeff.c_Psi)
    setvalue(m.coeff,trackCoeff.coeffCurvature)       # Track curvature
    setvalue(m.selStates,selStates)
    setvalue(m.statesCost,statesCost)

     # Solve Problem and return solution
    sol_status  = solve(m.mdl)
    sol_u       = getvalue(m.u_Ol)
    sol_z       = getvalue(m.z_Ol)

    # export data
    mpcSol.a_x = sol_u[1,1]
    mpcSol.d_f = sol_u[1,2]
    mpcSol.u   = sol_u
    mpcSol.z   = sol_z
    #mpcSol.eps_alpha = getvalue(m.eps_alpha)
    mpcSol.solverStatus = sol_status
    mpcSol.cost = zeros(6)
    #mpcSol.cost = [0,getvalue(m.terminalCost),getvalue(m.controlCost),getvalue(m.derivCost),0,getvalue(m.laneCost)]
    #println("o,terminal,control,deriv,0,lane= ",mpcSol.cost)

    println("Solved, status = $sol_status")

    nothing
end

function solveMpcProblem_obstacle(m::MpcModel_obstacle,mpcSol::MpcSol,mpcCoeff::MpcCoeff,mpcParams::MpcParams,trackCoeff::TrackCoeff,lapStatus::LapStatus,
                                  posInfo::PosInfo,modelParams::ModelParams,zCurr::Array{Float64},uPrev::Array{Float64},selectedStates::SelectedStates,
                                  obs_now::Array{Float64},obstacle::Obstacle)

 # Load Parameters
    sol_status::Symbol
    sol_u::Array{Float64,2}
    sol_z::Array{Float64,2}

    selStates       = selectedStates.selStates::Array{Float64,2}
    statesCost      = selectedStates.statesCost::Array{Float64,1}

    Q_obs           = mpcParams.Q_obs::Array{Float64,1}

#    println("Q_obs= ",Q_obs)

    obs      = zeros(mpcParams.N+1,3)
    obs[1,:] = obs_now

    # Compute the position of the obstacle  in the whole prediction horizon

    for i = 1:mpcParams.N
        obs[i+1,1] = obs[i,1] + modelParams.dt*i*obs[i,3]
        obs[i+1,2] = obs[i,2]
        obs[i+1,3] = obs[i,3]
    end

   # println("obstacle= ",obs)

    # Update current initial condition, curvature and System ID coefficients
    setvalue(m.z0,zCurr)
    setvalue(m.uPrev,uPrev)
    setvalue(m.c_Vx,mpcCoeff.c_Vx)            # System ID coefficients
    setvalue(m.c_Vy,mpcCoeff.c_Vy)
    setvalue(m.c_Psi,mpcCoeff.c_Psi)
    setvalue(m.coeff,trackCoeff.coeffCurvature)       # Track curvature
    setvalue(m.selStates,selStates)
    setvalue(m.statesCost,statesCost)
    setvalue(m.Q_obs,Q_obs)
    setvalue(m.obs,obs)

     # Solve Problem and return solution
    sol_status  = solve(m.mdl)
    sol_u       = getvalue(m.u_Ol)
    sol_z       = getvalue(m.z_Ol)

    # export data
    mpcSol.a_x = sol_u[1,1]
    mpcSol.d_f = sol_u[1,2]
    mpcSol.u   = sol_u
    mpcSol.z   = sol_z
    #mpcSol.eps_alpha = getvalue(m.eps_alpha)
    mpcSol.solverStatus = sol_status
    mpcSol.cost = zeros(6)
    mpcSol.cost = [0,getvalue(m.terminalCost),getvalue(m.controlCost),getvalue(m.derivCost),0,getvalue(m.laneCost)]

    mpcSol.costSlack = zeros(6)
    mpcSol.costSlack = [getvalue(m.slackVx),getvalue(m.slackVy),getvalue(m.slackPsidot),getvalue(m.slackEpsi),getvalue(m.slackEy),getvalue(m.slackS)]

    #println("cost for obstacle= ",getvalue(m.obstacleSlackCost))

    println("Solved, status = $sol_status")

    nothing
end