// Copyright (C) 2024 SocialSweet Inc.  All rights reserved.


#[test_only]
module collectible::test_transfer_policy {

    use std::string::{utf8};
    use std::debug;
    use std::type_name;
    use sui::coin;
    use sui::sui;
    use sui::package;
    use sui::test_scenario;
    use sui::transfer_policy;
    use sui::kiosk;
    use collectible::royalty_rule;
    use collectible::token;
    use collectible::test_common::{
        admin_publish_contract,
        admin_transfer_admin_caps,
        itos,
        coin_to_string,
        build_string,
    };
    use collectible::test_token::{
        admin_mint_token,
    };

    const ONE_SUI: u64 = 1_000_000_000_000; // 10^9 MIST

    // Integration tests

    #[test]
    fun test_add_transfer_policy() {
        let admin_addr = @0xAAAA;
        let minter_addr = @0xBBBB;
        let kiosk_addr = @0xCCCC;
        let user1 = @0xDDDD;
        let mut scenario = test_scenario::begin(@0x0);
        admin_publish_contract(&mut scenario, minter_addr);
        admin_transfer_admin_caps(&mut scenario, minter_addr, admin_addr);
        // As publisher, we register our transfer policy
        scenario.next_tx(admin_addr);
        {
            let transfer_policy_cap = scenario.take_from_sender<transfer_policy::TransferPolicyCap<token::Token>>();
            let mut transfer_policy = scenario.take_shared<transfer_policy::TransferPolicy<token::Token>>();
            // We then add one or more rules to the transfer policy
            royalty_rule::add(&mut transfer_policy, &transfer_policy_cap, 500);
            debug::print(&utf8(b"Publisher creates transfer policy rules for token"));
            scenario.return_to_sender(transfer_policy_cap);
            test_scenario::return_shared(transfer_policy);
        };
        // A kiosk marketplace is created by a 3rd party
        let kiosk_commission = 5; // 5% commission for kiosk owner
        scenario.next_tx(kiosk_addr);
        {
            kiosk::default(scenario.ctx());
        };
        // The minter mints a token and gives it to the kiosk
        let kiosk_asking_price = 10 * ONE_SUI;
        let kiosk_token_id;
        admin_mint_token(&mut scenario, 1, minter_addr, kiosk_addr);
        // The kiosk takes the token and lists it for sale
        scenario.next_tx(kiosk_addr);
        {
            let mut kiosk = scenario.take_shared<kiosk::Kiosk>();
            let kiosk_cap = scenario.take_from_sender<kiosk::KioskOwnerCap>();
            let token = scenario.take_from_sender<token::Token>();
            kiosk_token_id = object::id(&token); // save the token id for later
            let dbg_msg = build_string(&mut vector[
                utf8(b"Kiosk lists token "),
                kiosk_token_id.to_address().to_string(),
                utf8(b" for "),
                itos(kiosk_asking_price as u256),
                utf8(b" MIST"),
            ]);
            debug::print(&dbg_msg);
            kiosk::place_and_list(&mut kiosk, &kiosk_cap, token, kiosk_asking_price);
            scenario.return_to_sender(kiosk_cap);
            test_scenario::return_shared(kiosk);
        };

        // User researches a token that they are interested in buying and makes a note of all of the rules
        scenario.next_tx(user1);
        {
            // Give user 1 SUI (10^9 MIST) gas money so that they can pay for the token and all of the associated royalties
            let gas = coin::mint_for_testing<sui::SUI>(100 * ONE_SUI, scenario.ctx());
            let dbg_msg = build_string(&mut vector[
                utf8(b"User obtains "),
                coin_to_string(&gas),
                utf8(b" MIST for gas"),
            ]);
            debug::print(&dbg_msg);
            transfer::public_transfer(gas, scenario.ctx().sender());
            // User must determine the rules they must follow so they know what transaction to build in the next step
            let transfer_policy = scenario.take_shared<transfer_policy::TransferPolicy<token::Token>>();
            let rules = *transfer_policy.rules().keys();
            let mut i = rules.length();
            assert!(rules.length() > 0);
            let dbg_msg = build_string(&mut vector[
                utf8(b"User found "),
                itos(rules.length() as u256),
                utf8(b" rules for token"),
            ]);
            debug::print(&dbg_msg);
            while (i > 0) {
                let dbg_msg = build_string(&mut vector[
                    utf8(b"Rule #"),
                    itos(i as u256),
                    utf8(b": "),
                    rules[i - 1].into_string().to_string(),
                    utf8(b" -- "),
                    type_name::get<royalty_rule::Rule>().into_string().to_string(),

                ]);
                debug::print(&dbg_msg);
                i = i - 1;
            };
            test_scenario::return_shared(transfer_policy);
        };
        // User agrees to buy the token and pay all of the royalties
        scenario.next_tx(user1);
        {
            let mut gas_budget = scenario.take_from_sender<coin::Coin<sui::SUI>>();
            let mut kiosk = scenario.take_shared<kiosk::Kiosk>();
            let mut transfer_policy = scenario.take_shared<transfer_policy::TransferPolicy<token::Token>>();
            // User pays the kiosk asking price from their gas budget
            let payment_from_user = coin::split(&mut gas_budget, kiosk_asking_price, scenario.ctx());
            let mut dbg_msg;
            dbg_msg = build_string(&mut vector[
                utf8(b"User pays kiosk "),
                coin_to_string(&payment_from_user),
                utf8(b" MIST for token"),
            ]);
            debug::print(&dbg_msg);
            let (token, mut transfer_request) = kiosk.purchase<token::Token>(kiosk_token_id, payment_from_user);
            // User pays all of the royalties from their gas budget
            let royalty_amount = royalty_rule::fee_amount(&transfer_policy, kiosk_asking_price);
            let royalty_payment_from_user = coin::split(&mut gas_budget, royalty_amount, scenario.ctx());
            dbg_msg = build_string(&mut vector[
                utf8(b"User pays royalty of "),
                coin_to_string(&royalty_payment_from_user),
                utf8(b" MIST for token"),
            ]);
            debug::print(&dbg_msg);
            royalty_rule::pay(
                &mut transfer_policy, &mut transfer_request, royalty_payment_from_user
            );
            // User must then verify with the transfer_policy module  that all of the rules were correctly followed in order to complete the transaction
            let (item, paid, from) = transfer_policy::confirm_request(&transfer_policy, transfer_request);
            // Print out a receipt for the user
            let dbg_msg = build_string(&mut vector[
                utf8(b"Nft receipt for "),
                item.to_address().to_string(),
                utf8(b" cost "),
                itos(paid as u256),
                utf8(b" MIST from kiosk"),
                from.to_address().to_string(),
            ]);
            debug::print(&dbg_msg);
            // Token can not be transferred to our wallet
            transfer::public_transfer(token, scenario.ctx().sender());
            // return unused gas, etc back to sender
            scenario.return_to_sender(gas_budget);
            test_scenario::return_shared(transfer_policy);
            test_scenario::return_shared(kiosk);
        };
        // Kiosk owner takes their commission from the sale, and returns the proceeds to Sweet
        scenario.next_tx(kiosk_addr);
        {
            let mut kiosk = scenario.take_shared<kiosk::Kiosk>();
            let kiosk_cap = scenario.take_from_sender<kiosk::KioskOwnerCap>();
            // Kiosk owner takes the value of the sale, less their commission
            let mut sale_profit = kiosk::withdraw(&mut kiosk, &kiosk_cap, option::some(kiosk_asking_price), scenario.ctx());
            let commission_value = ((kiosk_asking_price as u128) * (kiosk_commission as u128) / 100) as u64;
            let commission = coin::split(&mut sale_profit, commission_value, scenario.ctx());
            // Print out value of sales and Kiosk's commission
            let dbg_msg = build_string(&mut vector[
                utf8(b"Proceeds of sales: "),
                coin_to_string(&sale_profit),
                utf8(b" MIST"),
            ]);
            debug::print(&dbg_msg);
            let dbg_msg = build_string(&mut vector[
                utf8(b"Commission to kiosk: "),
                coin_to_string(&commission),
                utf8(b" MIST"),
            ]);
            debug::print(&dbg_msg);
            // Commission and sales proceeds are transferred back
            transfer::public_transfer(sale_profit, minter_addr);
            transfer::public_transfer(commission, scenario.ctx().sender());
            // Put everything back
            scenario.return_to_sender(kiosk_cap);
            test_scenario::return_shared(kiosk);
        };
        // The admin can take royalties from the rules
        scenario.next_tx(admin_addr);
        {
            let transfer_policy_cap = scenario.take_from_sender<transfer_policy::TransferPolicyCap<token::Token>>();
            let mut transfer_policy = scenario.take_shared<transfer_policy::TransferPolicy<token::Token>>();
            // Owner of the royalty cap can withdraw all of their royalties
            let royalty_proceeds = transfer_policy::withdraw(&mut transfer_policy, &transfer_policy_cap, option::none(), scenario.ctx());
            let dbg_msg = build_string(&mut vector[
                utf8(b"Royalties from sales: "),
                coin_to_string(&royalty_proceeds),
                utf8(b" MIST"),
            ]);
            debug::print(&dbg_msg);
            transfer::public_transfer(royalty_proceeds, scenario.ctx().sender());
            // Put everything back
            scenario.return_to_sender(transfer_policy_cap);
            test_scenario::return_shared(transfer_policy);
        };
        // Clean-up
        scenario.end();
    }

}
