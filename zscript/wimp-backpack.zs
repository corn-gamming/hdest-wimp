// The backpack from vanilla HDest

class HDBackpackReplacer : EventHandler
{
	override void WorldThingSpawned(WorldEvent e)
	{
		let T = e.Thing;

		if (
			T &&
			T.GetClassName() == "HDBackpack" &&
			HDBackpack(T).Owner
		)
		{
			HDBackpack hdb = HDBackpack(T);
			WIMPHDBackpack wimp;

			// Already has a backpack?
			if (hdb.Owner.FindInventory("WIMPHDBackpack"))
			{
				wimp = WIMPHDBackpack(Actor.Spawn("WIMPHDBackpack", hdb.Owner.pos));

				wimp.angle = hdb.owner.angle;
				wimp.A_ChangeVelocity(1.5, 0, 1, CVF_RELATIVE);
				wimp.vel += hdb.owner.vel;
			}
			else
			{
				hdb.Owner.GiveInventory("WIMPHDBackpack", 1);
				wimp = WIMPHDBackpack(hdb.Owner.FindInventory("WIMPHDBackpack"));
			}

			wimp.Storage = hdb.Storage;
			wimp.MaxCapacity = hdb.MaxCapacity;

			hdb.Destroy();
		}
	}
}

class WIMPHDBackpack : HDBackpack replaces HDBackpack
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
		WP.DrawHUDStuff(sb, hdw, hpl, Storage, "\c[Tan]Backpack");
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

				if (W.CheckSwitch(Owner, S)) return;

				if (
					W.HandleWIMP(Owner, S) ||
					W.HijackMouseInput(Owner, S)
				)
				{
					A_UpdateStorage();
				}
				else
				{
					A_BPReady();
					if (W.CheckMoveItem(Owner)) A_UpdateStorage();
				}
			}
			Goto ReadyEnd;
	}
}

// Random backpacks
class WildWIMPack : IdleDummy replaces WildBackpack
{
	override void PostBeginPlay()
	{
		Super.PostBeginPlay();
		let wimp = WIMPHDBackpack(Spawn("WIMPHDBackpack", pos, ALLOW_REPLACE));
		wimp.RandomContents();
		Destroy();
	}
}
