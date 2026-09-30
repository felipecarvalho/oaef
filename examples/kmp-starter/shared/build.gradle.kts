plugins {
    kotlin("multiplatform")
}

kotlin {
    jvm()
    iosX64()
    iosArm64()
    iosSimulatorArm64()

    sourceSets {
        commonMain.dependencies {
            // Common multiplatform dependencies
        }
        commonTest.dependencies {
            implementation(kotlin("test"))
        }
    }
}
