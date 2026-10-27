/*******************************************************************************
 #  SPDX-License-Identifier: GPL-3.0-or-later                                  #
 #  SPDX-FileCopyrightText: 2025 Drona Aviation                                #
 #  -------------------------------------------------------------------------  #
 #  Copyright (c) 2025 Drona Aviation                                          #
 #  All rights reserved.                                                       #
 #  -------------------------------------------------------------------------  #
 #  Author: Ashish Jaiswal (MechAsh) <AJ>                                      #
 #  Project: MagisV2                                                           #
 #  File: \src\main\API\PlutoPilot.h                                           #
 #  Created Date: Sat, 22nd Feb 2025                                           #
 #  Brief:                                                                     #
 #  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  #
 #  Last Modified: Sun, 7th Sep 2025                                           #
 #  Modified By: AJ                                                            #
 #  - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  #
 #  HISTORY:                                                                   #
 #  Date      	By	Comments                                                   #
 #  ----------	---	---------------------------------------------------------  #
*******************************************************************************/

#ifndef _PlutoPilot_H_
#define _PlutoPilot_H_

#include "Comman.h"
#include "Control.h"
#include "Estimate.h"
#include "Localisation.h"
#include "Motor.h"
#include "Peripheral.h"
#include "Sensor.h"
#include "Specifiers.h"
#include "User.h"
#include "Utils.h"
#include "XRanging.h"
#include "RxConfig.h"

void plutoRxConfig ( void );

void plutoInit ( void );

void onLoopStart ( void );

void plutoLoop ( void );

void onLoopFinish ( void );

#endif
