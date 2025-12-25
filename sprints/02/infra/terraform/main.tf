provider "random" {}

resource "random_pet" "preview" {
  length = 2
}
