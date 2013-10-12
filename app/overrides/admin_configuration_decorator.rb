Deface::Override.new(:virtual_path => "spree/admin/shared/_configuration_menu",
                     :name => "add_paga_transaction_link_configuration_menu",
                     :insert_bottom => "[data-hook='admin_configurations_sidebar_menu']",
                     :text => %q{<%= configurations_sidebar_menu_item Spree.t("paga_transactions"), admin_paga_transactions_path %>},
                     :disabled => false)
