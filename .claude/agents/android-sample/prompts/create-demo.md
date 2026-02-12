# Create New Demo

## Task
Create a new demo showcasing [FEATURE/SCENARIO].

## Steps

1. **Create JSON Configuration** (`assets/[demo-name].json`)
   - Define theme
   - Add variables for dynamic content
   - Build node tree
   - Test in JSON validator

2. **Create Demo Composable** (`demos/[DemoName]Demo.kt`)
   ```kotlin
   @Composable
   fun [DemoName]Demo() {
       val json = loadAssetAsString("[demo-name].json")
       val config = Json.decodeFromString<NativeDisplayConfig>(json)

       NativeDisplayView(config)
   }
   ```

3. **Add Navigation** (MainActivity.kt)
   ```kotlin
   NavigationItem(
       title = "[Demo Name]",
       onClick = { navController.navigate("demo-name") }
   )
   ```

4. **Test Demo**
   - Verify rendering
   - Test interactions
   - Check on different screen sizes
   - Verify RTL layout

## Demo Checklist
- [ ] JSON configuration valid
- [ ] Variables used for dynamic content
- [ ] Style cascading demonstrated
- [ ] Layout responsive
- [ ] Comments explain key concepts
- [ ] Screenshot captured
- [ ] Added to navigation
- [ ] Tested on device

## Best Practices
- Keep JSON readable (formatted, commented)
- Use meaningful IDs
- Demonstrate one concept clearly
- Include both static and dynamic examples
- Show error handling if applicable
