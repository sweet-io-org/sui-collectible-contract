// Copyright (C) 2024 SocialSweet Inc.  All rights reserved.

#[test_only]
module collectible::test_token {

    use std::debug;
    use std::string::{utf8};
    use sui::display;
    use sui::test_scenario;
    use sui::test_scenario::EEmptyInventory;
    use collectible::moment;
    use collectible::token;
    use collectible::test_common::{
        admin_burn_publisher,
        admin_create_new_display_template,
        admin_custom_display_template,
        admin_publish_contract,
        admin_transfer_admin_caps,
        build_string,
        check_last_receipt,
        get_alt_token_data,
        get_new_alt_moment,
        transfer_minter_cap,
        owner_transfer_token,
    };
    use collectible::caps;

    // Integration tests

    #[test]
    fun test_mint_one_moment() {
        let admin_addr = @0xAAAA;
        let minter_addr = @0xBBBB;
        let user1 = @0xDDDD;
        let mut scenario = test_scenario::begin(@0x0);
        admin_publish_contract(&mut scenario, minter_addr);
        admin_transfer_admin_caps(&mut scenario, minter_addr, admin_addr);
        admin_update_display_template(&mut scenario, admin_addr,
            b"https://myproj.com",
            b"https://mylink.com",
            b"New copyright notice",
            b"New Series");
        admin_mint_token(&mut scenario, 1, minter_addr, user1);
        admin_update_display_template(&mut scenario, admin_addr,
            b"https://myproj2.com",
            b"https://mylink2.com",
            b"New copyright notice2",
            b"New Series2");
        owner_transfer_token<token::Token>(&mut scenario, user1, admin_addr);
        admin_update_token(&mut scenario, admin_addr,
            b"New name", b"New Description2",
            b"New PreviewImage2", 2);
        let alt_moment = get_new_alt_moment();
        admin_update_moment(&mut scenario, admin_addr, &alt_moment);
        admin_burn_token(&mut scenario, admin_addr);
        scenario.end();
    }

    #[test]
    #[expected_failure(abort_code = token::EInvalidRequest)]
    fun test_cannot_mint_edition_zero() {
        let admin_addr = @0xAAAA;
        let user1 = @0xCCCC;
        let mut scenario = test_scenario::begin(@0x0);
        admin_publish_contract(&mut scenario, admin_addr);
        admin_update_display_template(&mut scenario, admin_addr,
            b"https://myproj.com",
            b"https://mylink.com",
            b"New copyright notice",
            b"New Series");
        admin_mint_token(&mut scenario, 0, admin_addr, user1);
        scenario.end();
    }


    #[test]
    #[expected_failure(abort_code = EEmptyInventory)]
    fun test_minter_cap_required_to_mint() {
        let admin_addr = @0xAAAA;
        let minter_addr = @0xBBBB;
        let user1 = @0xCCCC;
        let mut scenario = test_scenario::begin(@0x00);
        admin_publish_contract(&mut scenario, minter_addr);
        transfer_minter_cap(&mut scenario, admin_addr, minter_addr);
        // Check minting fails with only admin_cap
        admin_mint_token(&mut scenario, 1, admin_addr, user1);
        // clean up
        scenario.end();
    }

    // === Admin token updates ===

    #[test]
    fun test_mint_not_related_to_admin_cap() {
        let admin_addr = @0xAAAA;
        let minter_addr = @0xBBBB;
        let mut scenario = test_scenario::begin(@0x00);
        admin_publish_contract(&mut scenario, minter_addr);
        admin_transfer_admin_caps(&mut scenario, minter_addr, admin_addr);
        admin_mint_token(&mut scenario, 1, minter_addr, minter_addr);
        // Clean up
        scenario.end();
    }


    #[test]
    fun test_update_not_related_to_minter_cap() {
        let unused_addr = @0xAAAA;
        let minter_addr = @0xBBBB;
        let mut scenario = test_scenario::begin(@0x00);
        admin_publish_contract(&mut scenario, minter_addr);
        admin_mint_token(&mut scenario, 1, minter_addr, minter_addr);
        transfer_minter_cap(&mut scenario, minter_addr, unused_addr);
        // Update everything on the token
        let alt_token_data = get_alt_token_data();
        admin_update_name(&mut scenario, minter_addr, alt_token_data[0]);
        admin_update_description(&mut scenario, minter_addr, alt_token_data[1]);
        admin_update_preview_image(&mut scenario, minter_addr, alt_token_data[2]);
        // admin_update_project_url(&mut scenario, minter_addr, alt_token_data[4]);
        admin_update_edition_number(&mut scenario, minter_addr, 2);
        // Update the moment data
        let alt_moment = get_new_alt_moment();
        admin_update_moment(&mut scenario, minter_addr, &alt_moment);
        // Clean up
        scenario.end();
    }


    #[test]
    fun test_admin_can_update_token() {
        let admin_addr = @0xAAAA;
        let unused_addr = @0xDDDD;
        let mut scenario = test_scenario::begin(@0x00);
        admin_publish_contract(&mut scenario, admin_addr);
        // Give token to the minter
        admin_mint_token(&mut scenario, 1, admin_addr, admin_addr);
        // transfer minter cap away
        transfer_minter_cap(&mut scenario, admin_addr, unused_addr);
        // Check that the admin can update everything
        let alt_token_data = get_alt_token_data();
        admin_update_name(&mut scenario, admin_addr, alt_token_data[0]);
        admin_update_description(&mut scenario, admin_addr, alt_token_data[1]);
        admin_update_preview_image(&mut scenario, admin_addr, alt_token_data[2]);
        admin_update_edition_number(&mut scenario, admin_addr, 2);
        // Update the moment data
        let alt_moment = get_new_alt_moment();
        admin_update_moment(&mut scenario, admin_addr, &alt_moment);
        // Clean up
        scenario.end();
    }

    // === Unauthorized token updates and burns ===

    #[test]
    #[expected_failure(abort_code = EEmptyInventory)]
    fun test_user_cannot_update_token_name() {
        let admin_addr = @0xAAAA;
        let user1 = @0xCCCC;
        let mut scenario = test_scenario::begin(@0x00);
        admin_publish_contract(&mut scenario, admin_addr);
        admin_mint_token(&mut scenario, 1, admin_addr, user1);
        // Check User cannot update the name
        admin_update_name(&mut scenario, user1, b"New Name");
        scenario.end();
    }

    #[test]
    #[expected_failure(abort_code = EEmptyInventory)]
    fun test_user_cannot_update_token_description() {
        let admin_addr = @0xAAAA;
        let user1 = @0xCCCC;
        let mut scenario = test_scenario::begin(@0x00);
        admin_publish_contract(&mut scenario, admin_addr);
        admin_mint_token(&mut scenario, 1, admin_addr, user1);
        // Check User cannot update the description
        admin_update_description(&mut scenario, user1, b"New Description");
        scenario.end();
    }

    #[test]
    #[expected_failure(abort_code = EEmptyInventory)]
    fun test_user_cannot_update_token_preview_image() {
        let admin_addr = @0xAAAA;
        let user1 = @0xCCCC;
        let mut scenario = test_scenario::begin(@0x00);
        admin_publish_contract(&mut scenario, admin_addr);
        admin_mint_token(&mut scenario, 1, admin_addr, user1);
        // Check User cannot update the preview image
        admin_update_preview_image(&mut scenario, user1, b"New Image");
        scenario.end();
    }

    #[test]
    #[expected_failure(abort_code = EEmptyInventory)]
    fun test_user_cannot_update_edition_number() {
        let admin_addr = @0xAAAA;
        let user1 = @0xCCCC;
        let mut scenario = test_scenario::begin(@0x00);
        admin_publish_contract(&mut scenario, admin_addr);
        admin_mint_token(&mut scenario, 1, admin_addr, user1);
        // Check User1 cannot update the token URI
        admin_update_edition_number(&mut scenario, user1, 2);
        scenario.end();
    }

    #[test]
    #[expected_failure(abort_code = EEmptyInventory)]
    fun test_user_cannot_update_moment() {
        let admin_addr = @0xAAAA;
        let user1 = @0xCCCC;
        let mut scenario = test_scenario::begin(@0x00);
        admin_publish_contract(&mut scenario, admin_addr);
        admin_mint_token(&mut scenario, 1, admin_addr, user1);
        // Check User1 cannot update the token URI
        admin_update_moment(&mut scenario, user1, &get_new_alt_moment());
        scenario.end();
    }

    #[test]
    #[expected_failure(abort_code = EEmptyInventory)]
    fun test_user_cannot_burn_token() {
        let admin_addr = @0xAAAA;
        let user1 = @0xCCCC;
        let mut scenario = test_scenario::begin(@0x00);
        admin_publish_contract(&mut scenario, admin_addr);
        admin_mint_token(&mut scenario, 1, admin_addr, user1);
        // User attempting an admin only function
        admin_burn_token(&mut scenario, user1);
        // clean up
        scenario.end();
    }


    // === Unit tests on the core functionality

    #[test]
    fun test_mint_moment() {
        let mut ctx = tx_context::dummy();
        let minterCap = caps::dummy_minter_cap(&mut ctx);
        let adminCap = caps::dummy_admin_cap(&mut ctx);
        // mint a new token
        let mut token = mint_and_validate_token(1, &minterCap,  &mut ctx);

        // Update our token data
        let updated_token_data = get_alt_token_data();
        update_and_verify_name(&mut token, updated_token_data[0], &adminCap);
        update_and_verify_description(&mut token, updated_token_data[1], &adminCap);
        update_and_verify_preview_image(&mut token, updated_token_data[2], &adminCap);
        update_and_verify_edition_number(&mut token, 2, &adminCap);

        // Update the moment data
        let new_moment = get_new_alt_moment();
        update_and_verify_moment(&mut token, &new_moment, &adminCap);

        // Burn the token
        token.burn(&adminCap, &mut ctx);

        // Clean up our caps
        caps::delete_dummy_admin_cap(adminCap);
        caps::delete_dummy_minter_cap(minterCap);
    }

    #[test]
    #[expected_failure(abort_code = token::EInvalidRequest)]
    fun test_invalid_edition_number() {
        let mut ctx = tx_context::dummy();
        let minterCap = caps::dummy_minter_cap(&mut ctx);
        // Create a token with an invalid edition number which is expected to fail
        let invalid_edition_number = 0;
        let token = mint_and_validate_token(invalid_edition_number, &minterCap, &mut ctx);
        transfer::public_transfer(token, @0x0);
        caps::delete_dummy_minter_cap(minterCap);
    }

    // Extended tests on Display behavior

    #[test]
    fun test_addition_of_custom_display_field() {
        let admin_addr = @0xAAAA;
        let minter_addr = @0xBBBB;
        let mut scenario = test_scenario::begin(@0x00);
        admin_publish_contract(&mut scenario, minter_addr);
        admin_transfer_admin_caps(&mut scenario, minter_addr, admin_addr);
        admin_mint_token(&mut scenario, 1, minter_addr, minter_addr);
        // Sui is an evolving blockchain, so check that we can
        // adjust the display template with custom fields for
        // new field-names that we might want to adopt.
        admin_custom_display_template(&mut scenario, admin_addr);
        scenario.end();
    }


    #[test]
    #[expected_failure(abort_code = test_scenario::EEmptyInventory)]
    fun test_only_owner_can_update_display_template() {
        let admin_addr = @0xAAAA;
        let minter_addr = @0xBBBB;
        let mut scenario = test_scenario::begin(@0x00);
        admin_publish_contract(&mut scenario, minter_addr);
        admin_transfer_admin_caps(&mut scenario, minter_addr, admin_addr);
        admin_mint_token(&mut scenario, 1, minter_addr, minter_addr);
        // As minter (but not admin) attempt to update the display
        admin_custom_display_template(&mut scenario, minter_addr); // Should fail!
        scenario.end();
    }

    #[test]
    fun test_display_update_after_burning_publisher() {
        let admin_addr = @0xAAAA;
        let minter_addr = @0xBBBB;
        let mut scenario = test_scenario::begin(@0x00);
        admin_publish_contract(&mut scenario, minter_addr);
        admin_transfer_admin_caps(&mut scenario, minter_addr, admin_addr);
        admin_mint_token(&mut scenario, 1, minter_addr, minter_addr);
        // Burn the publisher cap
        admin_burn_publisher(&mut scenario, admin_addr);
        // Check that display can still be updated after publisher is burned
        admin_custom_display_template(&mut scenario, admin_addr);
        scenario.end();
    }

    #[test]
    fun test_create_new_display_template() {
        let admin_addr = @0xAAAA;
        let minter_addr = @0xBBBB;
        let mut scenario = test_scenario::begin(@0x00);
        admin_publish_contract(&mut scenario, minter_addr);
        admin_transfer_admin_caps(&mut scenario, minter_addr, admin_addr);
        admin_mint_token(&mut scenario, 1, minter_addr, minter_addr);
        // Attempt to create a new display object (replaces the old one)
        admin_create_new_display_template(&mut scenario, admin_addr);
        scenario.end();
    }

    #[test]
    #[expected_failure(abort_code = test_scenario::EEmptyInventory)]
    fun test_new_display_fails_after_burning_publisher() {
        let admin_addr = @0xAAAA;
        let minter_addr = @0xBBBB;
        let mut scenario = test_scenario::begin(@0x00);
        admin_publish_contract(&mut scenario, minter_addr);
        admin_transfer_admin_caps(&mut scenario, minter_addr, admin_addr);
        admin_mint_token(&mut scenario, 1, minter_addr, minter_addr);
        // Burn the publisher cap
        admin_burn_publisher(&mut scenario, admin_addr);
        // Attempt to create a new display object
        admin_create_new_display_template(&mut scenario, admin_addr); // Should fail
        scenario.end();
    }

    // === Token Actions ===

    public fun mint_and_validate_token(edition_number: u16, minterCap: &caps::MinterCap, ctx: &mut TxContext): token::Token {
        let name = b"My name";
        let description = b"My description";
        let preview_image = b"My preview_image";
        let team = b"My Team";
        let player = b"My Player";
        let date = b"My Date";
        let play = b"My Play";
        let play_of_game = b"My play of game";
        let game_clock = b"My Game Clock";
        let audio_type = b"My Audio Type";
        let video = b"My video URI";
        let rarity: vector<u8> = b"My Rarity";
        let set: vector<u8> = b"My Set";
        let total_editions: u16 = 50;
        // Generate a unique URI for each mint
        let mut uri = b"My URI #";
        uri.append(edition_number.to_string().into_bytes());
        // Mint the token
        let mut vu8_vec: vector<vector<u8>> = vector::empty();
        vu8_vec.push_back(name);
        vu8_vec.push_back(description);
        vu8_vec.push_back(preview_image);
        vu8_vec.push_back(uri);
        vu8_vec.push_back(team);
        vu8_vec.push_back(player);
        vu8_vec.push_back(date);
        vu8_vec.push_back(play);
        vu8_vec.push_back(play_of_game);
        vu8_vec.push_back(game_clock);
        vu8_vec.push_back(audio_type);
        vu8_vec.push_back(video);
        vu8_vec.push_back(rarity);
        vu8_vec.push_back(set);
        let mut edition_data: vector<u16> = vector::empty();
        edition_data.push_back(edition_number);
        edition_data.push_back(total_editions);
        
        let token = token::mint(
            vu8_vec,
            edition_data,
            minterCap,
            ctx,
        );
        // Verify the outcome
        assert!(token.edition_number() == edition_number);
        assert!(token.name() == utf8(name));
        assert!(token.description() == utf8(description));
        assert!(token.preview_image() == utf8(preview_image));
        let mut expected_token_uri = utf8(b"https://nft.mlsquest.com");
        expected_token_uri.append(utf8(uri));
        assert!(token.uri() == expected_token_uri);
        assert!(token.moment().team() == utf8(team));
        assert!(token.moment().player() == utf8(player));
        assert!(token.moment().date() == utf8(date));
        assert!(token.moment().play() == utf8(play));
        assert!(token.moment().play_of_game() == utf8(play_of_game));
        assert!(token.moment().game_clock() == utf8(game_clock));
        assert!(token.moment().audio_type() == utf8(audio_type));
        assert!(token.moment().video() == utf8(video));
        assert!(token.moment().rarity() == utf8(rarity));
        assert!(token.moment().set() == utf8(set));
        token
    }

    fun update_and_validate_display(display: &mut display::Display<token::Token>,
            new_project_url: vector<u8>,
            new_link_url: vector<u8>,
            new_copyright: vector<u8>,
            new_series: vector<u8>, 
            _ctx: &mut tx_context::TxContext,
        ) {
        let mut expected_proj_url = utf8(new_project_url);
        expected_proj_url.append(utf8(b"{uri_path}"));
        let mut expected_link_url = utf8(new_link_url);
        expected_link_url.append(utf8(b"{uri_path}"));
        assert!(display.fields().try_get(&utf8(b"project_url")).get_with_default(utf8(b"")) != expected_proj_url);
        assert!(display.fields().try_get(&utf8(b"link")).get_with_default(utf8(b"")) != expected_link_url);
        assert!(display.fields().try_get(&utf8(b"series")).get_with_default(utf8(b"")) != utf8(new_series));
        token::set_display_template(display, new_project_url, new_link_url, new_copyright, new_series);
        assert!(display.fields().try_get(&utf8(b"project_url")).get_with_default(utf8(b"")) == expected_proj_url);
        assert!(display.fields().try_get(&utf8(b"link")).get_with_default(utf8(b"")) == expected_link_url);
        assert!(display.fields().try_get(&utf8(b"series")).get_with_default(utf8(b"")) == utf8(new_series));
    }

    fun admin_update_display_template(scenario: &mut test_scenario::Scenario, admin_addr: address,
            new_project_url: vector<u8>,
            new_link_url: vector<u8>,
            new_copyright: vector<u8>,
            new_series: vector<u8>,) {
        scenario.next_tx(admin_addr);
        {
            let mut display = scenario.take_from_sender<display::Display<token::Token>>();
            // Temporarily add ourselves to the whitelist
            update_and_validate_display(
                &mut display,
                new_project_url,
                new_link_url,
                new_copyright,
                new_series,
                scenario.ctx());
            // Remove ourselves from the whitelist
            scenario.return_to_sender(display);
        };
        // Expect one emitted event for updating display
        check_last_receipt(scenario, 0, 0, 0, 1);
    }

    public fun admin_mint_token(scenario: &mut test_scenario::Scenario, edition_number: u16, admin_addr: address, user: address) {
        scenario.next_tx(admin_addr);
        {
            let minter = scenario.take_from_sender<caps::MinterCap>();
            let token = mint_and_validate_token(edition_number, &minter, scenario.ctx());
            transfer::public_transfer(token, user);
            scenario.return_to_sender(minter);
        };
        // Expect one created object, and one emitted event for minting
        check_last_receipt(scenario, 1, 0, 0, 1);
    }

    public fun admin_burn_token(scenario: &mut test_scenario::Scenario, admin_addr: address) {
        scenario.next_tx(admin_addr);
        {
            let adminCap = scenario.take_from_sender<caps::AdminCap>();
            let token = scenario.take_from_sender<token::Token>();
            let dbg_string = build_string(&mut vector[
                utf8(b"Burning token '"),
                token.edition_number().to_string(),
                utf8(b"'"),
            ]);
            debug::print(&dbg_string);
            token.burn(&adminCap, scenario.ctx());
            scenario.return_to_sender(adminCap);
        };
        // Expect one destroyed object, and one emitted event for burning
        check_last_receipt(scenario, 0, 1, 0, 1);
    }

    // === Token updates ===

    public fun update_and_verify_name(
            token: &mut token::Token,
            new_name: vector<u8>,
            adminCap: &caps::AdminCap,
    ) {
        let exp_name = utf8(new_name);
        assert!(token.name() != exp_name);
        let dbg_string = build_string(&mut vector[
            utf8(b"Update name from '"),
            token.name(),
            utf8(b"' to '"),
            exp_name,
            utf8(b"'"),
        ]);
        debug::print(&dbg_string);
        token.update_name(new_name, adminCap);
        assert!(token.name() == exp_name);
    }

    public fun update_and_verify_description(
            token: &mut token::Token,
            new_description: vector<u8>,
            adminCap: &caps::AdminCap,
    ) {
        let exp_description = utf8(new_description);
        assert!(token.description() != exp_description);
        let dbg_string = build_string(&mut vector[
            utf8(b"Update description from '"),
            token.description(),
            utf8(b"' to '"),
            exp_description,
            utf8(b"'"),
        ]);
        debug::print(&dbg_string);
        token.update_description(new_description, adminCap);
        assert!(token.description() == exp_description);
    }
    public fun update_and_verify_preview_image(
            token: &mut token::Token,
            new_preview_image: vector<u8>,
            adminCap: &caps::AdminCap,
    ) {
        let exp_preview_image = utf8(new_preview_image);
        let dbg_string = build_string(&mut vector[
            utf8(b"Update preview image from '"),
            token.preview_image(),
            utf8(b"' to '"),
            exp_preview_image,
            utf8(b"'"),
        ]);
        debug::print(&dbg_string);
        assert!(token.preview_image() != exp_preview_image);
        token.update_preview_image(new_preview_image, adminCap);
        assert!(token.preview_image() == exp_preview_image);
    }

    public fun update_and_verify_edition_number(
            token: &mut token::Token,
            new_edition_number: u16,
            adminCap: &caps::AdminCap,
    ) {
        assert!(token.edition_number() != new_edition_number);
        let dbg_string = build_string(&mut vector[
            utf8(b"Update edition number from '"),
            token.edition_number().to_string(),
            utf8(b"' to '"),
            new_edition_number.to_string(),
            utf8(b"'"),
        ]);
        debug::print(&dbg_string);
        token.update_edition_number(new_edition_number, adminCap);
        assert!(token.edition_number() == new_edition_number);
    }

    public fun update_and_verify_moment(
            token: &mut token::Token,
            new_moment: &moment::Moment,
            adminCap: &caps::AdminCap,
    ) {
        // Update the token
        let moment = token.get_mut_moment(adminCap);
        assert!(moment != new_moment);
        let dbg_string = build_string(&mut vector[
            utf8(b"Updating moment e.g. '"),
            moment.player(),
            utf8(b"' => '"),
            new_moment.player(),
            utf8(b"', etc"),
        ]);
        debug::print(&dbg_string);
        moment.update(new_moment);
        assert!(moment == new_moment);
    }

    // === Token Admin actions ===


    public fun admin_update_name(scenario: &mut test_scenario::Scenario, owner_addr: address, new_name: vector<u8>) {
        scenario.next_tx(owner_addr);
        {
            let mut token = scenario.take_from_sender<token::Token>();
            let adminCap = scenario.take_from_sender<caps::AdminCap>();
            update_and_verify_name(&mut token, new_name, &adminCap);
            scenario.return_to_sender(token);
            scenario.return_to_sender(adminCap);
        };
        check_last_receipt(scenario, 0, 0, 0, 0);
    }

    public fun admin_update_description(scenario: &mut test_scenario::Scenario, owner_addr: address, new_description: vector<u8>) {
        scenario.next_tx(owner_addr);
        {
            let mut token = scenario.take_from_sender<token::Token>();
            let adminCap = scenario.take_from_sender<caps::AdminCap>();
            update_and_verify_description(&mut token, new_description, &adminCap);
            scenario.return_to_sender(token);
            scenario.return_to_sender(adminCap);
        };
        check_last_receipt(scenario, 0, 0, 0, 0);
    }

    public fun admin_update_preview_image(scenario: &mut test_scenario::Scenario, owner_addr: address, new_image: vector<u8>) {
        scenario.next_tx(owner_addr);
        {
            let mut token = scenario.take_from_sender<token::Token>();
            let adminCap = scenario.take_from_sender<caps::AdminCap>();
            update_and_verify_preview_image(&mut token, new_image, &adminCap);
            scenario.return_to_sender(token);
            scenario.return_to_sender(adminCap);
        };
        check_last_receipt(scenario, 0, 0, 0, 0);
    }

    public fun admin_update_edition_number(scenario: &mut test_scenario::Scenario, owner_addr: address, new_edition_number: u16) {
        scenario.next_tx(owner_addr);
        {
            let mut token = scenario.take_from_sender<token::Token>();
            let adminCap = scenario.take_from_sender<caps::AdminCap>();
            update_and_verify_edition_number(&mut token, new_edition_number, &adminCap);
            scenario.return_to_sender(token);
            scenario.return_to_sender(adminCap);
        };
        check_last_receipt(scenario, 0, 0, 0, 0);
    }

    public fun admin_update_token(scenario: &mut test_scenario::Scenario, admin_addr: address,
            new_name: vector<u8>,
            new_description: vector<u8>,
            new_preview_image: vector<u8>,
            new_edition_number: u16,
    ) {
        scenario.next_tx(admin_addr);
        {
            let adminCap = scenario.take_from_sender<caps::AdminCap>();
            let mut token = scenario.take_from_sender<token::Token>();
            // Update the token
            assert!(token.name() != utf8(new_name));
            assert!(token.description() != utf8(new_description));
            assert!(token.preview_image() != utf8(new_preview_image));
            assert!(token.edition_number() != new_edition_number);
            let dbg_string = build_string(&mut vector[
                utf8(b"Updating token e.g. '"),
                token.edition_number().to_string(),
                utf8(b"' => '"),
                new_edition_number.to_string(),
                utf8(b"', etc"),
            ]);
            debug::print(&dbg_string);
            token.update_name(new_name, &adminCap);
            token.update_description(new_description, &adminCap);
            token.update_preview_image(new_preview_image, &adminCap);
            token.update_edition_number(new_edition_number, &adminCap);
            assert!(token.name() == utf8(new_name));
            assert!(token.description() == utf8(new_description));
            assert!(token.preview_image() == utf8(new_preview_image));
            assert!(token.edition_number() == new_edition_number);
            // Clean up
            scenario.return_to_sender(token);
            scenario.return_to_sender(adminCap);
        };
        check_last_receipt(scenario, 0, 0, 0, 0);
    }

    public fun admin_update_moment(scenario: &mut test_scenario::Scenario, admin_addr: address, new_moment: &moment::Moment) {
        scenario.next_tx(admin_addr);
        {
            let adminCap = scenario.take_from_sender<caps::AdminCap>();
            let mut token = scenario.take_from_sender<token::Token>();
            update_and_verify_moment(&mut token, new_moment, &adminCap);
            // Clean up
            scenario.return_to_sender(token);
            scenario.return_to_sender(adminCap);
        };
        check_last_receipt(scenario, 0, 0, 0, 0);
    }

}
