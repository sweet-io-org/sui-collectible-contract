#[test_only]

module collectible::test_unique_ids {

    use sui::test_scenario;
    use sui::vec_set::{EKeyAlreadyExists, EKeyDoesNotExist};
    use collectible::uniqueidset;

    #[test]
    fun test_add_ids() {
        let admin = @0xAD;
        let mut scenario = test_scenario::begin(admin);
        scenario.next_tx(admin);
        {
            let mut idset = uniqueidset::new_set(scenario.ctx());
            idset.insert(0xAAAA0001);
            idset.insert(0xAAAA0002);
            idset.insert(0xBBBB0001);
            let mut idvec: vector<u32> = vector::empty();
            idvec.push_back(0xAAAA0003);
            idvec.push_back(0xBBBB0002);
            idvec.push_back(0xBBBB0003);
            idset.insert_all(idvec);
            transfer::public_transfer(idset, admin);
        };
        scenario.next_tx(admin);
        {
            let mut idset = scenario.take_from_sender<uniqueidset::UniqueIdSet>();
            assert!(idset.contains(0xAAAA0001));
            assert!(idset.contains(0xAAAA0002));
            assert!(idset.contains(0xAAAA0003));
            assert!(idset.contains(0xBBBB0001));
            // assert!(idset.contains(0xBBBB0002));
            scenario.return_to_sender(idset);
        };
        scenario.end();
    }

    #[test]
    #[expected_failure(abort_code = EKeyAlreadyExists)]
    fun test_dupe_insert1() {
        let admin = @0xAD;
        let mut scenario = test_scenario::begin(admin);
        scenario.next_tx(admin);
        {
            let mut idset = uniqueidset::new_set(scenario.ctx());
            idset.insert(0xAAAA0001);
            idset.insert(0xAAAA0002);
            idset.insert(0xAAAA0001);
            transfer::public_transfer(idset, admin);
        };
        scenario.end();
    }

    #[test]
    #[expected_failure(abort_code = EKeyAlreadyExists)]
    fun test_dupe_list_insert() {
        let admin = @0xAD;
        let mut scenario = test_scenario::begin(admin);
        scenario.next_tx(admin);
        {
            let mut idset = uniqueidset::new_set(scenario.ctx());
            idset.insert(0xAAAA0001);
            idset.insert(0xAAAA0002);
            let mut idvec: vector<u32> = vector::empty();
            idvec.push_back(0xAAAA0003);
            idvec.push_back(0xAAAA0004);
            idvec.push_back(0xAAAA0002);
            idset.insert_all(idvec);
            transfer::public_transfer(idset, admin);
        };
        scenario.end();
    }

    #[test]
    fun test_remove() {
        let admin = @0xAD;
        let mut scenario = test_scenario::begin(admin);
        scenario.next_tx(admin);
        {
            let mut idset = uniqueidset::new_set(scenario.ctx());
            idset.insert(0xAAAA0001);
            idset.insert(0xAAAA0002);
            let mut idvec: vector<u32> = vector::empty();
            idvec.push_back(0xAAAA0003);
            idvec.push_back(0xAAAA0004);
            idvec.push_back(0xAAAA0005);
            idset.insert_all(idvec);
            transfer::public_transfer(idset, admin);
        };
        scenario.next_tx(admin);
        {
            let mut idset = scenario.take_from_sender<uniqueidset::UniqueIdSet>();
            idset.remove(0xAAAA0003);
            scenario.return_to_sender(idset);
        };
        scenario.next_tx(admin);
        {
            let mut idset = scenario.take_from_sender<uniqueidset::UniqueIdSet>();
            assert!(!idset.contains(0xAAAA0003));
            scenario.return_to_sender(idset);
        };
        scenario.end();
    }


    #[test]
    #[expected_failure(abort_code = 1)]    
    fun test_remove_nonexistent_key() {
        let admin = @0xAD;
        let mut scenario = test_scenario::begin(admin);
        scenario.next_tx(admin);
        {
            let mut idset = uniqueidset::new_set(scenario.ctx());
            idset.insert(0xAAAA0000);
            idset.insert(0xAAAA0001);
            let mut idvec: vector<u32> = vector::empty();
            idvec.push_back(0xAAAA0002);
            idvec.push_back(0xAAAA0003);
            idvec.push_back(0xAAAA0004);
            idset.insert_all(idvec);
            transfer::public_transfer(idset, admin);
        };
        scenario.next_tx(admin);
        {
            let mut idset = scenario.take_from_sender<uniqueidset::UniqueIdSet>();
            idset.remove(0xAAAA0005);
            scenario.return_to_sender(idset);
        };
        scenario.end();        
    }

}
        
        