pub fn add(left: i32, right: i32) -> i32 {
    left + right
}

pub fn multiply(left: i32, right: i32) -> i32 {
    left * right
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_adds() {
        assert_eq!(add(2, 3), 5);
    }

    #[test]
    fn it_multiplies() {
        assert_eq!(multiply(3, 4), 12);
    }
}
