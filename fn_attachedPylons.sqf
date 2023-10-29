#include "\z\pya\addons\main\script_component.hpp" 

/*
Sample commands: [vehicle,"ON"] spawn uAVm_fnc_attachedPylons;
[vehicle,"ARM",0] spawn uAVm_fnc_attachedPylons;
[vehicle,"RC",[0,0,unit]] spawn uAVm_fnc_attachedPylons; //remote control requires pylon group and pylon id parameters; pylon must be armed for option to appear.
Pylons should no longer show in uav menu list, as uav connectability with player is disabled.

Add this line to parent vehicle init: [this,"INIT"] spawn uAVm_fnc_attachedPylons;  //deletes crew of pylon and sets "Status" variable.
These variables must be added to the vehicle which has the pylons mounted, as conditions for menus options.  pyaPgrp variable defines active pylon group.
	this setVariable ["pyaPylonStatus",0];
	this setVariable ["pyaPgrp",-1];
These variables are added to the pylons.  One to check if the pylon is active (in _linkedPylons list and with a crew), the other to define pylon group.
	this setVariable ["Status",0];
	this setVariable ["pgroup",[0,"Cannons",0]]; // syntax [pylon group,group name, pylon]  If you want the group name to be undefined, and use the current pylon magazine name instead; use name "var".
These actions must be added to vehicles that have pylons armed either on the init or via a script / trigger: 

	this addAction ["Activate Pylons",{[(_this select 0),"ON"] spawn uAVm_fnc_attachedPylons}, nil, 1.5, false, false, "", "_target getVariable 'pyaPylonStatus' < 1 && _target == getConnectedUAV player", -1, false, "", ""];
	this addAction ["Deactivate Pylons",{[(_this select 0),"OFF"] spawn uAVm_fnc_attachedPylons}, nil, 1.5, false, false, "", "_target getVariable 'pyaPylonStatus' > 0 && _target == getConnectedUAV player", -1, false, "", ""];
	this addAction ["Arm 7.62mm Minigun",{[(_this select 0),"ARM",0] spawn uAVm_fnc_attachedPylons}, nil, 1.5, false, false, "", "_target getVariable 'pyaPylonStatus' > 0 && _target getVariable 'pyaPgrp' != 0 && _target == getConnectedUAV player", -1, false, "", ""]; 
	this addAction ["Arm Rocket Pods",{[(_this select 0),"ARM",1] spawn uAVm_fnc_attachedPylons}, nil, 1.5, false, false, "", "_target getVariable 'pyaPylonStatus' > 0 && _target getVariable 'pyaPgrp' != 1 && _target == getConnectedUAV player", -1, false, "", ""]; 
	this addAction ["Arm ATGM",{[(_this select 0),"ARM",2] spawn uAVm_fnc_attachedPylons}, nil, 1.5, false, false, "", "_target getVariable 'pyaPylonStatus' > 0 && _target getVariable 'pyaPgrp' != 3 && _target == getConnectedUAV player", -1, false, "", ""];
	this addAction ["Check Weapon",{[(_this select 0),"RC",[0,0,(_this select 1)]] spawn uAVm_fnc_attachedPylons}, nil, 1.5, false, false, "", "_target getVariable 'pyaPylonStatus' > 0 && _target getVariable 'pyaPgrp' == 0 && _target == getConnectedUAV player", -1, false, "", ""]; 
	this addAction ["Check Weapon",{[(_this select 0),"RC",[1,0,(_this select 1)]] spawn uAVm_fnc_attachedPylons}, nil, 1.5, false, false, "", "_target getVariable 'pyaPylonStatus' > 0 && _target getVariable 'pyaPgrp' == 1 && _target == getConnectedUAV player", -1, false, "", ""]; 
	this addAction ["Check Weapon",{[(_this select 0),"RC",[1,1,(_this select 1)]] spawn uAVm_fnc_attachedPylons}, nil, 1.5, false, false, "", "_target getVariable 'pyaPylonStatus' > 0 && _target getVariable 'pyaPgrp' == 2 && _target == getConnectedUAV player", -1, false, "", ""];
	this addAction ["Check Weapon",{[(_this select 0),"RC",[2,0,(_this select 1)]] spawn uAVm_fnc_attachedPylons}, nil, 1.5, false, false, "", "_target getVariable 'pyaPylonStatus' > 0 && _target getVariable 'pyaPgrp' == 3 && _target == getConnectedUAV player", -1, false, "", ""];
	this addAction ["Check Ammo Stores",{[(_this select 0),"AMMO"] spawn uAVm_fnc_attachedPylons}, nil, 1.5, false, false, "", "_target == getConnectedUAV player", -1, false, "", ""];
Action conditions vary depending if parent vehicle is a drone, or current vehicle player is in. (either: _target == getConnectedUAV player OR _target == vehicle player)
For arming commands, action text can be customised to suit the weapon/s the pylon or pylon group has; conditions check the "pyaPgrp" variable of the parent vehicle; so if a pylon group is armed, the action to arm it no longer shows up until either another pylon group is selected or pylons are deactivated.  In the later case, pyaGroup variable is set back to default -1.
*/

_veh = _this select 0;  // Vehicle or drone which has the pylons attached
_mode = _this select 1; // "INIT", "ON", "OFF","ARM","AMMO","RC"
_pylonGrp = _this select 2; //Pylon group or [pylon group, pylon, caller] if mode is "RC"

_unit = call CBA_fnc_currentUnit;
private _pylon = "";
private _crew = "";
private _pgrp = 0;
private _unitsWithTrigger = [];
private _linkedPylons = _unit getVariable [QGVAR(linkedPylons), []];
private _armedPylons = _unit getVariable [QGVAR(armedPylons), []];

if (_mode == "INIT") exitWith
{
	{
		if (_x isKindOf "pya_main_base") then 
		{
			_pylon = _x;
			_pylon setVariable ["Status",0];
			_crew = count crew _pylon;
			if (_crew > 0) then
			{
				deleteVehicleCrew _pylon;
			};
		};
	} forEach attachedObjects _veh;
};
// ACTIVATE PYLONS		
if (_mode == "ON") exitWith
{
	_linkedPylons = [];
	_armedPylons = [];
	{
		if (_x isKindOf "pya_main_base") then 
		{
			_pylon = _x;
			_crew = count crew _pylon;
			if (_crew < 1) then
			{
				createVehicleCrew _pylon;
				sleep 0.001;
				group _pylon setCombatMode "BLUE";
				player disableUAVConnectability [_x,true];
			};
			_linkedPylons pushBackUnique _pylon;
			_unitsWithTrigger pushBackUnique _unit;
			_pylon setVariable [QGVAR(unitsWithTrigger), _unitsWithTrigger, true];
			_pylon setVariable ["Status",1];
		};
	} forEach attachedObjects _veh;
	_unit setVariable [QGVAR(armedPylons), _armedPylons, true];
	_unit setVariable [QGVAR(linkedPylons), _linkedPylons, true];
	_veh setVariable ["pyaPylonStatus",1];
	hint "Pylons Active";
	if (_veh == vehicle player) then
	{
		[_veh] spawn
		{
			_veh = _this select 0;
			waitUntil {sleep 1; (_veh != vehicle player && _veh getVariable "pyaPylonStatus" != 2)};
			if (_veh getVariable "pyaPylonStatus" > 0) then
			{
				[_veh,"OFF"] call uAVm_fnc_attachedPylons;
			};
		};
	} else {
		[_veh] spawn
		{
			_veh = _this select 0;
			waitUntil {sleep 1; (_veh != getConnectedUAV player && _veh getVariable "pyaPylonStatus" != 2)};
			if (_veh getVariable "pyaPylonStatus" > 0) then
			{
				[_veh,"OFF"] call uAVm_fnc_attachedPylons;
			};
		};
	};
};
if (_mode == "OFF") exitWith
{
	_linkedPylons = [];
	_armedPylons = [];
	{
		if (_x isKindOf "pya_main_base") then 
		{
			_pylon = _x;
			_crew = count crew _pylon;
			if (_crew > 0) then
			{
				deleteVehicleCrew _pylon;
			};
			_pylon setVariable [QGVAR(unitsWithTrigger), _unitsWithTrigger, true];
			_pylon setVariable ["Status",0];
		};
	} forEach attachedObjects _veh;
	_unit setVariable [QGVAR(armedPylons), _armedPylons, true];
	_unit setVariable [QGVAR(linkedPylons), _linkedPylons, true];
	_veh setVariable ["pyaPylonStatus",0];
	_veh setVariable ["pyaPgrp",-1];
	hint "Pylons Inactive";
};
if (_mode == "ARM") exitWith
{
	_armedPylons = [];
	private _armed = 0;
	private _fail = 0;
	private _str0 = "";
	private _str1 = "";
//	private _str2 = "pylon is";
//	private _str3 = "is";
	private _magazine = "";
	private _pgrpname = "";
	{
		if (_x isKindOf "pya_main_base") then 
		{
			_pylon = _x;
			_pgrp = _pylon getVariable "pgroup" select 0;
			if (_pgrp == _pylonGrp) then
			{
				_pgrpname = _pylon getVariable "pgroup" select 1;
				if (_pgrpname == "var") then
				{
					_magazine = getPylonMagazines _pylon select 0;
					_pgrpname = getText (configFile >> "CfgMagazines" >> _magazine >> "displayName");
				};
				_status = _pylon getVariable "Status";
				if (_status > 0) then
				{
					_armedPylons pushBack _pylon;
					_armed = _armed + 1;
				} else {
					//_fail = _fail + 1; //Removed failure option.  Changed to create crew for pylon and arm it if pylons have not been activated.
					_crew = count crew _pylon;
					if (_crew < 1) then
					{
						createVehicleCrew _pylon;
						sleep 0.001;
						group _pylon setCombatMode "BLUE";
						player disableUAVConnectability [_x,true];
					};
					_armedPylons pushBack _pylon;
					_linkedPylons pushBackUnique _pylon;
					_unitsWithTrigger pushBackUnique _unit;
					_pylon setVariable [QGVAR(unitsWithTrigger), _unitsWithTrigger, true];
					_pylon setVariable ["Status",1];
				};			
			};
		};
	} forEach attachedObjects _veh;
	_veh setVariable ["pyaPgrp",_pylonGrp];
	_unit setVariable [QGVAR(armedPylons), _armedPylons, true];
	_unit setVariable [QGVAR(linkedPylons), _linkedPylons, true];
	if (_armed > 0) then 
	{
		if (_armed > 1) then {_str1 = " group"; _str2 = "pylons are"};
/*
// Conditions for hint messages are now redundant, given there will no longer be failures in arming pylons
		switch true do
		{
			case (_fail < 1):{_str0 = parseText format ["Pylon%1 %2 (%3) is armed",_str1,_pylonGrp,_pgrpname]};
			case (_fail > 0):
			{
				if (_fail > 1) then
				{
					_str3 = "are";
				};
				_str0 = parseText format ["%1 %2 armed, %3 %4 inactive",_armed,_str2,_fail,_str3];
			};
		};
	} else {
		_str0 = parseText format ["Pylon%1 %2 (%3) is inactive",_str1,_pylonGrp,_pgrpname];*/
	};
	_str0 = parseText format ["Pylon%1 %2 (%3) is armed",_str1,_pylonGrp,_pgrpname];
	hint _str0;
	if (_veh getVariable "pyaPylonStatus" < 1) then
	{
		_veh setVariable ["pyaPylonStatus",1];
		if (_veh == vehicle player) then
		{
			[_veh] spawn
			{
				_veh = _this select 0;
				waitUntil {sleep 1; (_veh != vehicle player && _veh getVariable "pyaPylonStatus" != 2)};
				if (_veh getVariable "pyaPylonStatus" > 0) then
				{
					[_veh,"OFF"] call uAVm_fnc_attachedPylons;
				};
			};
		} else {
			[_veh] spawn
			{
				_veh = _this select 0;
				waitUntil {sleep 1; (_veh != getConnectedUAV player && _veh getVariable "pyaPylonStatus" != 2)};
				if (_veh getVariable "pyaPylonStatus" > 0) then
				{
					[_veh,"OFF"] call uAVm_fnc_attachedPylons;
				};
			};
		};
	};
};
if (_mode == "AMMO") exitWith
{
	private _arr = [];
	private _str = [];
	private _str0 = [];
	private _str1 = [];
	private _str2 = parseText "<t size = '1.1' color='#ffff00'>AMMO STORES</t><br/>";
	private _magazine = "";
	private _magname = "";
	private _ammo = "";
	_str0 = _str0 + [_str2];
	{
		if (_x isKindOf "pya_main_base") then 
		{
			_pylon = _x;
			_pgrp = _pylon getVariable "pgroup" select 0;
			_magazine = getPylonMagazines _pylon select 0;
			_magname = getText (configFile >> "CfgMagazines" >> _magazine >> "displayName");
			_ammo = magazinesAmmo _pylon select 0 select 1;
			_str2 = parseText format ["<t size = '0.9' color='#ffff00' align='left'>[Group %1] </t><t size = '0.9' color='#00ff00' align='left'>%2:</t><t size = '0.9' align='right'> %3</t><br/>",_pgrp,_magname,_ammo];
			_arr = [_str2,_pgrp];
			_str1 = _str1 + [_arr];
		};
	} forEach attachedObjects _veh;
	_str3 = _str1 apply {[_x#1,_x#0]};
	_str3 sort true;
	_str1 = [];
	{_str1 = _str1 + [_x select 1]} forEach _str3;
	_str0 = _str0 + _str1;
	_str = composeText _str0;
	hint _str;
};
if (_mode == "RC") exitWith
{
	_veh setVariable ["pyaPylonStatus",2];
	{
		if (_x isKindOf "pya_main_base") then 
		{
			_pylon = _x;
			_pgrp = _pylon getVariable "pgroup" select 0;
			_pid = _pylon getVariable "pgroup" select 2;
			_unit = _pylonGrp select 2;
			if ((_pgrp == _pylonGrp select 0) && (_pid == _pylonGrp select 1)) then
			{
				if ((remoteControlled gunner _veh != player) AND (remoteControlled driver _veh != player)) then
				{
					_crew = count crew _pylon;
					if (_crew < 1) then
					{
						createVehicleCrew _pylon;
						sleep 0.001;
						group _pylon setCombatMode "BLUE";
						player disableUAVConnectability [_x,true];
					};
					sleep 0.5;
					_unit remoteControl gunner _pylon;
					gunner _pylon switchCamera "internal";
				} else {
					hint "You must not be controlling the drone in order to adjust the weapon";
				};			
			};
		};
	} forEach attachedObjects _veh;
	[_pylon,_veh,_unit] spawn 
	{
		waitUntil {sleep 1; ((remoteControlled gunner (_this select 0) != (_this select 2)) AND (remoteControlled driver (_this select 0) != (_this select 2)))};
		(_this select 1) setVariable ["pyaPylonStatus",1];
	};
};