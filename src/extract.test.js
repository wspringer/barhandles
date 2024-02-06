const { extract, extractSchema } = require("./index");

describe("extract", () =>  {
    let emit = null;

    beforeEach(() => (emit = jest.fn()));

    it("should allow you to extract simple references", function () {
        extract("{{foo.bar}}", emit);
        expect(emit).toHaveBeenCalledWith(["foo", "bar"], false);
    });

    it("should support 'each'", function () {
        extract("{{#each foo}}{{bar}}{{/each}}", emit);
        expect(emit).toHaveBeenCalledWith(["foo", "#", "bar"], false);
    });

    it("should support 'each' without getting hung up on @index", function () {
        extract(
            `\
{{#each foo}}{{@index}}{{/each}}\
`,
            emit
        );
        expect(emit).not.toHaveBeenCalledWith(["foo", "#", "index"], false);
    });

    it("should support 'with'", function () {
        extract("{{#with foo}}{{bar}}{{/with}}", emit);
        expect(emit).toHaveBeenCalledWith(["foo", "bar"], false);
    });

    it("should support '@root'", function () {
        extract("{{#each foo.bar}}{{@root.bar}}{{/each}}", emit);
        expect(emit).toHaveBeenCalledWith(["bar"], false);
    });

    it("should support '../'", function () {
        extract("{{#with foo}}{{#each bar}}{{../baz}}{{/each}}{{/with}}", emit);
        expect(emit).toHaveBeenCalledWith(["foo", "baz"], false);
    });

    it("should be able to deal with simple extensions", function () {
        extract("{{alt foo.bar foo.baz}}", emit);
        expect(emit).toHaveBeenCalledWith(["foo", "bar"], false);
        expect(emit).toHaveBeenCalledWith(["foo", "baz"], false);
    });

    it("should support generating a schema", function () {
        expect(extractSchema).toBeDefined();
        expect(typeof extractSchema).toBe("function");
        const template = `\
{{#each foo}}
  {{bar}}
  {{@root.baz}}
  {{../baz}}
{{/each}}\
`;
        const schema = extractSchema(template);
        expect(schema).toHaveProperty("foo");
        expect(schema.foo).toHaveProperty("_type", "array");
        expect(schema).toHaveProperty("baz");
        expect(schema.baz).toHaveProperty("_type", "any");
        expect(schema.foo).toHaveProperty("#");
        expect(schema.foo["#"]).toHaveProperty("bar");
        expect(schema.foo["#"].bar).toHaveProperty("_type", "any");
    });

    it("should handle simple helpers correctly", function () {
        extract("{{currency amount}}", emit);
        expect(emit).toHaveBeenCalledWith(["amount"], false);
    });

    it("should deal with ifs in a meaningful way", function () {
        extract("{{#if foo}}{{foo.bar}}{{/if}}", emit);
        expect(emit).toHaveBeenCalledWith(["foo"], true);
        expect(emit).toHaveBeenCalledWith(["foo", "bar"], true);
    });

    it("should deal with optionals correctly while generating a schema", function () {
        const template = `\
{{foo.baz}}
{{#if foo}}
{{@root.go}}
{{foo.bar.yoyo}}
{{/if}}\
`;
        const schema = extractSchema(template);
        expect(schema).toHaveProperty("foo");
        expect(schema.foo).toHaveProperty("_optional", false);
        expect(schema.foo).toHaveProperty("bar");
        expect(schema.foo.bar).toHaveProperty("_optional", true);
    });

    it("should allow you to add definitions for other directives", function () {
        const template = `\
{{alt foo.bar foo.baz}}\
`;
        extract(template, emit, {
            alt: {
                optional: true
            }
        });
        expect(emit).toHaveBeenCalledWith(["foo", "bar"], true);
    });

    it("should consider all parts of a ternary operator to be optional", function () {
        const template = `\
{{ternary foo.bar foo.baz foo.gum}}\
`;
        const schema = extractSchema(template, {
            ternary: {
                optional: true
            }
        });
        expect(schema).toHaveProperty("foo.bar._optional", true);
        expect(schema).toHaveProperty("foo.baz._optional", true);
        expect(schema).toHaveProperty("foo.gum._optional", true);
    });

    it("should ignore variables starting with @", function () {
        const template = `\
{{@foo.bar}}\
`;
        const schema = extractSchema(template);
        expect(schema).not.toHaveProperty("foo");
    });

    it("should not consider something with length property to be an object", function () {
        const template = `\
{{foo.length}}\
`;
        const schema = extractSchema(template);
        expect(schema).toHaveProperty("foo");
        expect(schema.foo).toHaveProperty("_type", "any");
    });
});
