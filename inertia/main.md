Inertia related stuff

# Form state 

## Inertia forms, reflecting prop updates
This is for components that are being filled from the inertia connection, data that is being provided at load, not async or self contained loads.

Essentially need to use refs to avoid infinite loops as the state will update from the save
```js
const { patch, setData, data, errors } = useForm<{
    stops: ShipmentStop[];
}>({
    stops: getSavedStops(),
});

const setDataRef = useRef(setData);

useEffect(() => {
    setDataRef.current({
        stops: getSavedStops(),
    });
}, [stops, getSavedStops]);
```
