module "metabase_db"{
    source = "./database"
}

module "metabase_bastion"{
    source = "./bastion"
}

module "metabase_app"{
    source = "./metabase"
}

module "metabase_lb"{
    source = "./load_balancer"
}

module "metabase_routers"{
    source = "./routers"
}