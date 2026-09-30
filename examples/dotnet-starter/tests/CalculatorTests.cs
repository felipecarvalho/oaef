using Xunit;
using DotnetStarter;

namespace DotnetStarter.Tests;

public sealed class CalculatorTests
{
    private readonly Calculator calculator = new();

    [Fact]
    public void Add_CalculatesSumCorrectly()
    {
        var result = calculator.Add(5, 7);
        Assert.Equal(12, result);
    }

    [Fact]
    public void Multiply_CalculatesProductCorrectly()
    {
        var result = calculator.Multiply(4, 6);
        Assert.Equal(24, result);
    }
}
