<?php declare(strict_types=1);

namespace GuestPriceVisibility\Subscriber;

use Symfony\Component\HttpFoundation\RedirectResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\EventDispatcher\EventSubscriberInterface;
use Symfony\Component\HttpKernel\Event\ControllerEvent;
use Symfony\Component\HttpKernel\Event\ResponseEvent;
use Symfony\Component\HttpKernel\KernelEvents;
use Symfony\Component\Routing\Generator\UrlGeneratorInterface;

class GuestPriceVisibilitySubscriber implements EventSubscriberInterface
{
    // Routes that would expose the cart or a price and must stay blocked for guests.
    private const BLOCKED_ROUTES = [
        'frontend.checkout.cart.page',
        'frontend.checkout.confirm.page',
        'frontend.checkout.finish.page',
        'frontend.checkout.line-item.add',
        'frontend.checkout.line-item.delete',
        'frontend.checkout.line-item.update-quantity',
        'frontend.checkout.line-item.add-by-number',
        'frontend.checkout.line-item.change-payment-shipping',
    ];

    // Ajax header widget that renders the cart badge/preview; suppressed instead of redirected.
    private const SUPPRESSED_ROUTES = [
        'widgets.checkout.info',
    ];

    public function __construct(private readonly UrlGeneratorInterface $router)
    {
    }

    public static function getSubscribedEvents(): array
    {
        return [
            KernelEvents::CONTROLLER => 'onController',
            KernelEvents::RESPONSE => 'onResponse',
        ];
    }

    public function onController(ControllerEvent $event): void
    {
        if (!$event->isMainRequest()) {
            return;
        }

        $request = $event->getRequest();
        if (!$this->isGuest($request)) {
            return;
        }

        $route = (string) $request->attributes->get('_route');

        if (\in_array($route, self::SUPPRESSED_ROUTES, true)) {
            $event->setController(static fn () => new Response('', Response::HTTP_NO_CONTENT));
            return;
        }

        if (\in_array($route, self::BLOCKED_ROUTES, true)) {
            $loginUrl = $this->router->generate('frontend.account.login.page');
            $event->setController(static fn () => new RedirectResponse($loginUrl));
        }
    }

    public function onResponse(ResponseEvent $event): void
    {
        if (!$event->isMainRequest()) {
            return;
        }

        $request = $event->getRequest();
        $response = $event->getResponse();

        if (!$this->isGuest($request)) {
            return;
        }

        if (!str_contains((string) $response->headers->get('Content-Type'), 'text/html')) {
            return;
        }

        $content = $response->getContent();
        if (!is_string($content) || stripos($content, '</head>') === false) {
            return;
        }

        $style = '<style id="guest-price-visibility">'
            // Hide all price and "from price" hints, e.g. "Varianten ab 133,88 EUR".
            . '[class*="price" i]{visibility:hidden!important;} '
            .'.guest-price-hidden,.product-price,.product-detail-price,.product-box-price,'
            .'.cart-item-price,.checkout-aside-summary-value,[itemprop="price"],[itemprop="lowPrice"]'
            . '{visibility:hidden!important;} '
            .'.guest-price-hidden::after,.product-price::after,.product-detail-price::after,.product-box-price::after,'
            .'.cart-item-price::after,.checkout-aside-summary-value::after'
            . '{content:"Preis nach Anmeldung sichtbar";visibility:visible!important;display:inline-block;} '
            // Remove add-to-cart controls so no price can be revealed via the cart.
            .'.btn-buy,.product-detail-buy,.buy-widget,.buy-widget-container,'
            .'[data-add-to-cart],form[action*="checkout/line-item"]'
            . '{display:none!important;} '
            .'</style>';

        $response->setContent(str_ireplace('</head>', $style . '</head>', $content));
    }

    private function isGuest(Request $request): bool
    {
        $salesChannelContext = $request->attributes->get('sw-sales-channel-context');
        if (!is_object($salesChannelContext) || !method_exists($salesChannelContext, 'getCustomer')) {
            return false;
        }

        return $salesChannelContext->getCustomer() === null;
    }
}
