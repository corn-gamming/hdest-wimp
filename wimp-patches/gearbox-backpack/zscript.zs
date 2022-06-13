version 4.6.0

class WIMP_HDGearBoxReplacer : EventHandler
{
	override void WorldThingSpawned(WorldEvent e)
	{
		let gearBox = HDGearBox(e.Thing);
		if (!(
			gearBox &&
			gearBox.GetClassName() == "HDGearBox" &&
			gearBox.Owner
		)) return;

		gearBox.Owner.GiveInventory("WIMP_HDGearBox", 1);

		let wimpBox = WIMP_HDGearBox(gearBox.Owner.FindInventory("WIMP_HDGearBox"));
		wimpBox.Storage = gearBox.Storage;
		wimpBox.MaxCapacity = wimpBox.MaxCapacity;

		gearBox.Destroy();
	}
}

class WIMP_HDGearBox : HDGearBox replaces HDGearBox
{
	WIMPack WP;

	override void BeginPlay()
	{
		Super.BeginPlay();
		WP = new("WIMPack");
		WP.WIMP = new("WIMPItemStorage");
		WP.WOMP = new("WOMPItemStorage");
	}

	override void DrawHUDStuff(HDStatusBar sb, HDWeapon hdw, HDPlayerPawn hpl)
	{
		WP.DrawHUDStuff(
			sb,
			hpl,
			Storage,
			"\c[DarkBrown][] [] [] \c[Ice]GearBox \c[DarkBrown][] [] []",
			"Total Bulk: \c[Gold]"..int(Storage.TotalBulk).."\c-"
		);
	}

	States
	{
		Select0:
			// Initialize shit to (try) prevent reading from address zero
			TNT1 A 10
			{
				A_UpdateStorage();
				Invoker.WP.SyncStorage(invoker.Storage);
				A_StartSound("weapons/pocket", CHAN_WEAPON);
				if (invoker.Storage.TotalBulk > (HDCONST_BPMAX * 0.7))
				{
					A_SetTics(20);
				}
			}
			TNT1 A 0 A_Raise(999);
			Wait;

		Ready:
			TNT1 A 1
			{
				ItemStorage S = Invoker.Storage;
				WIMPack W = Invoker.WP;
				HDPlayerPawn Owner = HDPlayerPawn(Invoker.Owner);
				if (!Owner.Player) return;

				W.GetCVars(Owner.Player);
				W.SyncStorage(S);
				A_UpdateStorage();

				if (W.CheckSwitch(Owner, S)) return;

				if (
					!(
					W.HandleWIMP(Owner, S) ||
					W.HijackMouseInput(Owner, S)
					)
				)
				{
					A_BPReady();
				}
			}
			Goto ReadyEnd;
	}
}