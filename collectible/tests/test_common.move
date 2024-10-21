// Copyright (C) 2024 SocialSweet Inc.  All rights reserved.

#[test_only]
module collectible::test_common {

    use std::debug;
    use std::string::{from_ascii, String, utf8};
    use std::type_name;
    use sui::coin;
    use sui::display;
    use sui::package;
    use sui::test_scenario;
    use sui::transfer_policy;
    
    use collectible::caps;
    use collectible::moment;
    use collectible::token;
    use collectible::uniqueidset;

    const ZERO: u8 = 48;


    // === Common helper functions ===

    public fun get_token_data(): vector<vector<u8>> {
        vector [
            b"My Name",
            b"My Description",
            b"My Image",
            b"My Token Uri",
            b"My Project URL",
        ]
    }

    public fun get_alt_token_data(): vector<vector<u8>> {
        vector [
            b"Alt Token",
            b"Alt Description",
            b"Alt Image",
            b"Alt Token Uri",
            b"Alt Project URL",
        ]
    }

    public fun get_moment_data(): vector<vector<u8>> {
        vector[
            b"My Team",
            b"My Player",
            b"My Date",
            b"My Play",
            b"My Play Type",
            b"My Game Clock",
            b"My Audio Type",
            b"My Video",
        ]
    }

    public fun get_alt_moment_data(): vector<vector<u8>> {
        vector[
            b"Alt Team",
            b"Alt Player",
            b"Alt Date",
            b"Alt Play",
            b"Alt Play Type",
            b"Alt Game Clock",
            b"Alt Audio Type",
            b"Alt Video",
        ]
    }

    public fun get_new_moment(): moment::Moment {
        let moment_data = get_moment_data();
        moment::new_moment(
            moment_data[0], // Team
            moment_data[1], // Player
            moment_data[2], // Date
            moment_data[3], // Play
            moment_data[4], // Type of Play
            moment_data[5], // Game Clock
            moment_data[6], // Audio Type
            moment_data[7], // Video / primary media
            64,
        )
    }

    public fun get_new_alt_moment(): moment::Moment {
        let moment_data = get_alt_moment_data();
        moment::new_moment(
            moment_data[0], // Team
            moment_data[1], // Player
            moment_data[2], // Date
            moment_data[3], // Play
            moment_data[4], // Type of Play
            moment_data[5], // Game Clock
            moment_data[6], // Audio Type
            moment_data[7], // Video / primary media
            100,
        )
    }

    // === Admin Integration Functions ===

    fun dummy_upgrade_cap(package_addr: address, ctx: &mut TxContext): package::UpgradeCap {
        // Create a dummy upgrade pack
        let package_id = object::id_from_address(package_addr);
        sui::package::test_publish(package_id, ctx)
    }

    public fun admin_publish_contract(scenario: &mut test_scenario::Scenario, admin_addr: address) {
        // Initialize the Sweet packages
        scenario.next_tx(admin_addr);
        {
            let dbg_string = build_string(&mut vector[
                utf8(b"Publishing contract to '"),
                admin_addr.to_string(),
                utf8(b"'"),
            ]);
            debug::print(&dbg_string);
            // Initialize the SUI packages
            let upgrade_cap = dummy_upgrade_cap(admin_addr, scenario.ctx());
            transfer::public_transfer(upgrade_cap, admin_addr);
            // Perform all of the private init functions
            caps::test_init(scenario.ctx());
            token::test_init(scenario.ctx());
        };
        // Expect 8 created objects, and 1 emit for contract deployment
        check_last_receipt(scenario, 8, 0, 0, 2);
        scenario.next_tx(admin_addr);
        {
            let mut unique_id_set = scenario.take_from_sender<uniqueidset::UniqueIdSet>();
            unique_id_set.insert(1000);
            scenario.return_to_sender(unique_id_set);
        };
        scenario.next_tx(admin_addr);
        {
            let mut unique_id_set = scenario.take_from_sender<uniqueidset::UniqueIdSet>();
            assert!(unique_id_set.contains(1000));
            scenario.return_to_sender(unique_id_set);
        };
    }

    public fun admin_transfer_admin_caps(scenario: &mut test_scenario::Scenario,
            admin_addr: address, new_admin_addr: address) {
        scenario.next_tx(admin_addr);
        {
            let admin = scenario.take_from_sender<caps::AdminCap>();
            let publisher = scenario.take_from_sender<sui::package::Publisher>();
            let upgrade_cap = scenario.take_from_sender<sui::package::UpgradeCap>();
            let txf_policy_cap = scenario.take_from_sender<transfer_policy::TransferPolicyCap<token::Token>>();
            let display = scenario.take_from_sender<display::Display<token::Token>>();
            let dbg_string = build_string(&mut vector[
                utf8(b"Transferring caps to '"),
                new_admin_addr.to_string(),
                utf8(b"'"),
            ]);
            debug::print(&dbg_string);
            transfer::public_transfer(admin, new_admin_addr);
            transfer::public_transfer(upgrade_cap, new_admin_addr);
            transfer::public_transfer(publisher, new_admin_addr);
            transfer::public_transfer(display, new_admin_addr);
            transfer::public_transfer(txf_policy_cap, new_admin_addr);
        };
        check_last_receipt(scenario, 0, 0, 0, 0);
    }

    public fun transfer_minter_cap(scenario: &mut test_scenario::Scenario,
        from_addr: address, to_addr: address) {
        scenario.next_tx(from_addr);
        {
            let minter = scenario.take_from_sender<caps::MinterCap>();
            transfer::public_transfer(minter, to_addr);
        };
        check_last_receipt(scenario, 0, 0, 0, 0);
    }
        

    public fun admin_has_admin_cap_access(scenario: &mut test_scenario::Scenario, admin_addr: address) {
        scenario.next_tx(admin_addr);
        {
            let admin = scenario.take_from_sender<caps::AdminCap>();
            // No-op, just to confirm we have access
            scenario.return_to_sender(admin);
        };
        check_last_receipt(scenario, 0, 0, 0, 0);
    }

    public fun has_admin_cap(scenario: &mut test_scenario::Scenario): bool {
        let admin_ids = scenario.ids_for_sender<caps::AdminCap>();
        !admin_ids.is_empty()
    }

    public fun admin_has_minter_cap_access(scenario: &mut test_scenario::Scenario, admin_addr: address) {
        scenario.next_tx(admin_addr);
        {
            let minter = scenario.take_from_sender<caps::MinterCap>();
            // No-op, just to confirm we have access
            scenario.return_to_sender(minter);
        };
        check_last_receipt(scenario, 0, 0, 0, 0);
    }

    public fun has_minter_cap(scenario: &mut test_scenario::Scenario): bool {
        let minter_ids = scenario.ids_for_sender<caps::MinterCap>();
        !minter_ids.is_empty()
    }

    // === Owner Integration Functions ===

    public fun owner_cannot_get_caps(scenario: &mut test_scenario::Scenario, owner_addr: address) {
        scenario.next_tx(owner_addr);
        {
            // Confirm that the owner does not have admin cap or minter cap
            assert!(!has_admin_cap(scenario));
            assert!(!has_minter_cap(scenario));
        };
        check_last_receipt(scenario, 0, 0, 0, 0);
    }

    // Useful debug functions

    public fun build_string(parts: &mut vector<String>): String {
        let mut result: String = utf8(b"");
        while (!parts.is_empty()) {
            result.append(parts.remove(0));
        };
        result
    }

    public fun itos(mut value: u256): String {
        if (value == 0) {
            return utf8(vector[ZERO])
        };
        let mut result: vector<u8> = vector[];
        while (value > 0) {
            result.push_back((value % 10) as u8 + ZERO);
            value = value / 10;
        };
        result.reverse();
        utf8(result)
    }

    public fun coin_to_string<T>(amount: &coin::Coin<T>): String {
        if (amount.value() == 0) {
            return utf8(vector[ZERO])
        };
        let mut i = 0;
        let mut result: vector<u8> = vector[];
        let mut value = amount.value();
        while (value > 0) {
            if (i > 0 && (i % 3) == 0) {
                result.append(b"_");
            };
            i = i + 1;
            result.push_back((value % 10) as u8 + ZERO);
            value = value / 10;
        };
        result.reverse();
        utf8(result)
    }

    public fun owner_transfer_token<T: key+store>(scenario: &mut test_scenario::Scenario, owner_addr: address, to_addr: address) {
        scenario.next_tx(owner_addr);
        {
            let token = scenario.take_from_sender<T>();
            let dbg_string = build_string(&mut vector[
                utf8(b"Transferring token '"),
                from_ascii(type_name::get<T>().into_string()),
                utf8(b"' to user '"),
                to_addr.to_string(),
                utf8(b"'"),
            ]);
            debug::print(&dbg_string);
            transfer::public_transfer(token, to_addr);
        };
        check_last_receipt(scenario, 0, 0, 0, 0);
    }

    public fun check_last_receipt(scenario: &mut test_scenario::Scenario,
            nr_created: u64, nr_deleted: u64, nr_frozen: u64, nr_user_events: u64
    ):
        test_scenario::TransactionEffects
    {
        // Get last transaction receipt and set the invalidate the address
        let last_receipt = scenario.next_tx(@0x0);
        debug::print(&last_receipt.deleted().length());
        assert!(last_receipt.deleted().length() == nr_deleted);
        assert!(last_receipt.created().length() == nr_created);
        assert!(last_receipt.frozen().length() == nr_frozen);
        assert!(last_receipt.num_user_events() == nr_user_events);
        last_receipt
    }

    // Extended display tests

    fun add_and_verify_multiple_fields<T: key>(display: &mut display::Display<T>, new_fields: vector<String>, new_values: vector<String>) {
        // Add one or more fields and verify that they are uniquely added
        let mut i = new_fields.length();
        while (i > 0) {
            assert!(display.fields().contains(&new_fields[i - 1]) == false);
            i = i - 1;
        };
        display.add_multiple(new_fields, new_values);
        i = new_fields.length();
        while (i > 0) {
            assert!(display.fields().contains(&new_fields[i - 1]) == true);
            i = i - 1;
        };
    }

    public fun remove_and_verify_field<T: key>(display: &mut display::Display<T>, key: String) {
        // Remove field and verify that it is gone
        assert!(display.fields().contains(&key) == true);
        display.remove(key);
        assert!(display.fields().contains(&key) == false);
    }

    public fun edit_and_verify_field(
        display: &mut display::Display<token::Token>, key: String, new_value: String
    ) {
        // Edit field and verify that it changes
        assert!(display.fields().contains(&key) == true);
        assert!(display.fields().get(&key) != new_value);
        display.edit(key, new_value);
        assert!(display.fields().contains(&key) == true);
        assert!(display.fields().get(&key) == new_value);
    }


    public fun admin_custom_display_template(scenario: &mut test_scenario::Scenario, admin_addr: address) {
        // As Sui evolves as a blockchain, it may become necessary to make
        // custom changes to the Display template to reflect.
        //
        // See https://docs.sui.io/standards/display
        scenario.next_tx(admin_addr);
        {
            let mut display = scenario.take_from_sender<display::Display<token::Token>>();
            // Add a new field to the display template
            let new_fields = vector[
                utf8(b"animation_url"),
            ];
            let new_values = vector[
                utf8(b"{moment.video}"),
            ];
            add_and_verify_multiple_fields(&mut display, new_fields, new_values);
            // Remove one of the existing fields
            remove_and_verify_field(&mut display, utf8(b"video_url"));
            // Modify a value from one of these custom fields
            let key = utf8(b"animation_url");
            let new_value = utf8(b"{moment.video}?autoplay=true");
            edit_and_verify_field(&mut display, key, new_value);
            // Lastly we must inform others of this change
            display.update_version();
            // Clean up
            scenario.return_to_sender(display);
        };
        // Expect one change emitted when we bump the display template version
        check_last_receipt(scenario, 0, 0, 0, 1);
    }

    public fun admin_burn_publisher(scenario: &mut test_scenario::Scenario, admin_addr: address) {
        // Burning the publisher revokes all admin rights on the contract
        scenario.next_tx(admin_addr);
        {
            // Burn the publisher
            assert!(scenario.ids_for_sender<package::Publisher>().length() == 1);
            let publisher = scenario.take_from_sender<package::Publisher>();
            package::burn_publisher(publisher);
        };
    }

    public fun admin_create_new_display_template(scenario: &mut test_scenario::Scenario, admin_addr: address) {
        // In the event that the display object becomes compromised we
        // may need to generate a new Display object to replace the old one.
        //
        // Creating a new object will deprecate the old one.
        scenario.next_tx(admin_addr);
        {
            let publisher = scenario.take_from_sender<package::Publisher>();
            // Using our publisher cap, create a new display. Creating a new display
            // will make the old one become obsolete.
            let display = display::new<token::Token>(&publisher, scenario.ctx());
            transfer::public_transfer(display, admin_addr);
            // Clean up
            scenario.return_to_sender(publisher);
        };
        // Expect one new object and emit one create event when we make a new display template
        check_last_receipt(scenario, 1, 0, 0, 1);

    }

}
