// Copyright (C) 2024 SocialSweet Inc.  All rights reserved.

module collectible::caps {

    // Admin capabilities, can modify metadata for tokens    
    public struct AdminCap has key, store { id: UID }

    // Minter capabilities for highlights, can mint new NFTs
    public struct MinterCap has key, store { id: UID }

    // Packer capabilities, can add tokens to pack pools, burn packs, and remove tokens from the pool
    public struct PackerCap has key, store { id: UID }

    // Pack Minter capabilities, can mint new Pack NFTs
    public struct PackMinterCap has key, store { id: UID }

    #[test_only]
    /// Create a dummy `AdminCap` for testing
    public fun dummy_admin_cap(ctx: &mut TxContext): AdminCap {
        AdminCap {
            id: object::new(ctx),
        }
    }

    #[test_only]
    /// Create a dummy `MinterCap` for testing
    public fun dummy_minter_cap(ctx: &mut TxContext): MinterCap {
        MinterCap {
            id: object::new(ctx),
        }
    }

    #[test_only]
    /// Create a dummy `PackerCap` for testing
    public fun dummy_packer_cap(ctx: &mut TxContext): PackerCap {
        PackerCap {
            id: object::new(ctx),
        }
    }

    #[test_only]
    /// Allow delete of dummy admin cap
    public fun delete_dummy_admin_cap(admin: AdminCap) {
        let AdminCap { id: admin_cap_uid } = admin;
        object::delete(admin_cap_uid);
    }

    #[test_only]
    /// Allow delete of dummy minter cap
    public fun delete_dummy_minter_cap(minter: MinterCap) {
        let MinterCap { id: minter_cap_uid } = minter;
        object::delete(minter_cap_uid);
    }

    #[test_only]
    /// Allow delete of dummy pxkwe cap
    public fun delete_dummy_packer_cap(packer: PackerCap) {
        let PackerCap { id: packer_cap_uid } = packer;
        object::delete(packer_cap_uid);
    }

    public fun burn_minter(minter: MinterCap) {
        // only the minter can be deleted, prevents creation of new tokens only
        let MinterCap { id } = minter;
        object::delete(id);
    }

    public fun burn_pack_minter(pack_minter: PackMinterCap) {
        // only the minter can be deleted, prevents creation of new tokens only
        let PackMinterCap { id } = pack_minter;
        object::delete(id);
    }

    // === Module init ===

    fun init(ctx: &mut TxContext) {
        // Give the contract deployer admin and minter capabilities
        // Admin will be moved out after deployment
        transfer::transfer(AdminCap {
            id: object::new(ctx)
        }, tx_context::sender(ctx));

        // we want to create 3 minter caps to support parallelization
        transfer::transfer(MinterCap {
            id: object::new(ctx)
        }, tx_context::sender(ctx));
        transfer::transfer(MinterCap {
            id: object::new(ctx)
        }, tx_context::sender(ctx));
        transfer::transfer(MinterCap {
            id: object::new(ctx)
        }, tx_context::sender(ctx));

        // can add tokens to pack pools, burn packs, and remove tokens from the pool
        transfer::transfer(PackerCap {
            id: object::new(ctx)
        }, tx_context::sender(ctx));

        // and 3 pack minter caps
        // can mint new Pack NFTs
        transfer::transfer(PackMinterCap {
            id: object::new(ctx)
        }, tx_context::sender(ctx));
        transfer::transfer(PackMinterCap {
            id: object::new(ctx)
        }, tx_context::sender(ctx));
        transfer::transfer(PackMinterCap {
            id: object::new(ctx)
        }, tx_context::sender(ctx));
    }

    #[test_only]
    public fun test_init(ctx: &mut TxContext) {
        init(ctx);
    }
}
