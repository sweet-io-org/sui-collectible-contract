// Copyright (C) 2024 SocialSweet Inc.  All rights reserved.

module collectible::uniqueidset {
    // this is intended to be created for each Collectible Set, and owned by the Minter
    // at the start of each PTB, the sequence numbers being minted are inserted as a list,
    // and if any are already in the list, the PTB will fail.
    // the most-significant u16 will be relatively rare, only 20-40 unique values.
    // the least-significant u16 are much more common, and will represent the edition numbers

    use sui::vec_set::{Self, VecSet};

    const ENotFound: u64    = 0x200;

    public struct UniqueIdSet has key, store {
        id: UID,
        id1_values: vector<u16>,
        id2_sets: vector<VecSet<u16>>,
    }

    public fun new_set(ctx: &mut TxContext,): UniqueIdSet {
        UniqueIdSet {
            id: object::new(ctx),
            id1_values: vector::empty(),
            id2_sets: vector::empty(),
        }
    }

    public fun insert(self: &mut UniqueIdSet, unique_id: u32) {
        insert_impl(self, unique_id);
    }

    public fun remove(self: &mut UniqueIdSet, unique_id: u32) {
        let (rare_bits, common_bits) = split_unique_id(unique_id);
        let (set_exists, set_pos) = self.id1_values.index_of(&rare_bits);
        assert!(set_exists, ENotFound);
        // will error if item does not exist
        let unique_set = self.id2_sets.borrow_mut(set_pos);
        unique_set.remove(&common_bits);
    }

    public fun insert_all(self: &mut UniqueIdSet, unique_ids: vector<u32>) {
        // add a list of ids, if any are already in the set, will fail
        let mut i = 0;
        while (i < unique_ids.length()) {
            insert_impl(self, unique_ids[i]);
            i = i + 1;
        }
    }

    public fun contains(self: &UniqueIdSet, unique_id: u32): bool {
        let (rare_bits, common_bits) = split_unique_id(unique_id);
        let (set_exists, set_pos) = self.id1_values.index_of(&rare_bits);
        if (!set_exists) {
            return false
        };
        let unique_set = self.id2_sets.borrow(set_pos);
        unique_set.contains(&common_bits)
    }

    fun insert_impl(self: &mut UniqueIdSet, unique_id: u32) {
        let (rare_bits, common_bits) = split_unique_id(unique_id);
        let (set_exists, set_pos) = self.id1_values.index_of(&rare_bits);
        if (set_exists) {
            let unique_set = self.id2_sets.borrow_mut(set_pos);
            unique_set.insert(common_bits);        
        } else {
            let mut unique_set = vec_set::empty();
            unique_set.insert(common_bits);
            self.id1_values.push_back(rare_bits);
            self.id2_sets.push_back(unique_set);
        }
    }

    fun split_unique_id(unique_id: u32): (u16, u16) {
        let rare_bits = (((unique_id & 0xFFFF0000) >> 16) as u16);
        let common_bits = ((unique_id & 0xFFFF) as u16);
        (rare_bits, common_bits)
    }


}
        

